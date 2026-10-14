#===============================================================================
class Battle::Scene::FightMenu

  alias_method :ebs_nextgen_vanilla_initialize,          :initialize
  alias_method :ebs_nextgen_vanilla_dispose,             :dispose
  alias_method :ebs_nextgen_vanilla_z=,                  :z=
  alias_method :ebs_nextgen_vanilla_visible=,            :visible=
  alias_method :ebs_nextgen_vanilla_battler=,             :battler=
  alias_method :ebs_nextgen_vanilla_refreshButtonNames,  :refreshButtonNames
  alias_method :ebs_nextgen_vanilla_refreshSelection,    :refreshSelection
  alias_method :ebs_nextgen_vanilla_refreshMegaEvolutionButton, :refreshMegaEvolutionButton
  alias_method :ebs_nextgen_vanilla_refreshShiftButton,  :refreshShiftButton
  alias_method :ebs_nextgen_vanilla_refresh,             :refresh


  EliteBattleUI.import_config(self, EliteBattleUI::FightMenu)
  include EliteBattleUI::Text::Helpers

  def initialize(viewport, z)
    super(viewport)   # Battle::Scene::MenuBase#initialize
    self.x = 0
    self.y = Graphics.height - MENU_HEIGHT
    @battler   = nil
    @shiftMode = 0
    @moveButtonsBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "moveSelButtons")
    @menu_slide_offset_y  = 0
    @menu_logical_visible = nil 
    @menu_slide_start     = nil
    @menu_slide_hiding    = false

    if pbResolveBitmap(GRAPHICS_PATH + "newBattleMessageBox")
      @backgroundBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "newBattleMessageBox")
      background = Sprite.new(viewport)
      background.bitmap = @backgroundBitmap.bitmap
      addSprite("background", background)
    end

    @btn_local_y = Array.new(Pokemon::MAX_MOVES)

    @buttons = Array.new(Pokemon::MAX_MOVES) do |i|
      button = Sprite.new(viewport)
      addSprite("button_#{i}", button)
      next button
    end


    # Botón de Mega Evolución
    if pbResolveBitmap(GRAPHICS_PATH + "megaEvoButton")
      @megaEvoBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "megaEvoButton")
      @megaButton = Sprite.new(viewport)
      @megaButton.bitmap = @megaEvoBitmap.bitmap
      @megaButton.src_rect.set(106, 0, 44, 46)
      @megaButton.x = self.x + 8
      addSprite("megaButton", @megaButton)
      @visibility["megaButton"] = false
    end

    # Botón "volver"
    if pbResolveBitmap(GRAPHICS_PATH + "backButton")
      @backButtonBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "backButton")
      @backButton = Sprite.new(viewport)
      @backButton.bitmap = @backButtonBitmap.bitmap
      @backButton.x = self.x + 462
      addSprite("backButton", @backButton)
    end

    self.z = z

    # Deslizamiento entre movimientos
    @btn_anim_from_x    = Array.new(Pokemon::MAX_MOVES)
    @btn_anim_from_local_y = Array.new(Pokemon::MAX_MOVES)
    @btn_anim_to_x      = Array.new(Pokemon::MAX_MOVES)
    @btn_anim_to_local_y   = Array.new(Pokemon::MAX_MOVES)
    @btn_anim_start     = Array.new(Pokemon::MAX_MOVES)
    @buttons_positioned = false

    reposition_all
  end

  def dispose
    @buttons&.each { |b| b.bitmap.dispose if b.bitmap && !b.bitmap.disposed? }
    super
    @moveButtonsBitmap&.dispose
    @backgroundBitmap&.dispose
    @megaEvoBitmap&.dispose
    @backButtonBitmap&.dispose
  end

  def z=(value)
    super
    @buttons.each { |b| b.z = value + 3 }
    @megaButton.z = value + 1 if @megaButton
    @backButton.z = value + 1 if @backButton
  end

  def reposition_all
    bg = @sprites["background"]
    bg.y = self.y + @menu_slide_offset_y if bg
    @megaButton.y = self.y + @menu_slide_offset_y + 27 if @megaButton
    @backButton.y = self.y + @menu_slide_offset_y + 28 if @backButton
    apply_button_y_offsets
    refreshSelection if @battler
  end

  def apply_button_y_offsets
    Pokemon::MAX_MOVES.times do |i|
      button = @sprites["button_#{i}"]
      next if !button || !@btn_local_y[i]
      button.y = @btn_local_y[i] + @menu_slide_offset_y
    end
  end

  def offscreen_menu_offset
    MENU_SLIDE_DISTANCE
  end

  def visible=(value)
    if @menu_logical_visible.nil?

      @menu_logical_visible = value
      @menu_slide_offset_y  = value ? 0 : offscreen_menu_offset
      reposition_all
      self.ebs_nextgen_vanilla_visible = value
      return
    end
    return if value == @menu_logical_visible
    @menu_logical_visible = value
    if value && !self.visible

      @menu_slide_offset_y = offscreen_menu_offset
      reposition_all
      self.ebs_nextgen_vanilla_visible = true
    end
    @menu_slide_hiding      = !value
    @menu_slide_from_offset = @menu_slide_offset_y
    @menu_slide_to_offset   = value ? 0 : offscreen_menu_offset
    @menu_slide_start       = System.uptime
  end

  def menu_sliding?
    !@menu_slide_start.nil?
  end

  def tick_menu_slide
    return if !@menu_slide_start
    @menu_slide_offset_y = lerp(@menu_slide_from_offset, @menu_slide_to_offset, MENU_SLIDE_DURATION,
                                @menu_slide_start, System.uptime)
    bg = @sprites["background"]
    bg.y = self.y + @menu_slide_offset_y if bg
    @megaButton.y = self.y + @menu_slide_offset_y + 27 if @megaButton
    @backButton.y = self.y + @menu_slide_offset_y + 28 if @backButton
    apply_button_y_offsets
    return if @menu_slide_offset_y != @menu_slide_to_offset
    self.ebs_nextgen_vanilla_visible = false if @menu_slide_hiding
    @menu_slide_start = nil
  end

  def update
    super
    update_button_anim
  end


  def battler=(value)
    @battler = value
    generateButtons
    refresh
  end

  def shiftMode=(value)
    oldValue = @shiftMode
    @shiftMode = value
    refreshShiftButton if @shiftMode != oldValue
  end

  def generateButtons
    moves = (@battler) ? @battler.moves : []
    bmp = @moveButtonsBitmap.bitmap
    Pokemon::MAX_MOVES.times do |i|
      button = @sprites["button_#{i}"]
      next if !button
      button.bitmap.dispose if button.bitmap && !button.bitmap.disposed?
      move = moves[i]
      if !move || !move.id || move.id == 0
        @visibility["button_#{i}"] = false
        button.bitmap = nil
        next
      end
      begin
        @visibility["button_#{i}"] = true
        type = move.display_type(@battler)
        type_row = GameData::Type.get(type).icon_position

        cell = Bitmap.new(CELL_WIDTH * 2, CELL_HEIGHT)
        cell.blt(0, 0, bmp, Rect.new(0, CELL_HEIGHT * type_row, CELL_WIDTH, CELL_HEIGHT))

        cell.blt(CELL_WIDTH, 0, bmp, Rect.new(CELL_WIDTH, CELL_HEIGHT * type_row, CELL_WIDTH, CELL_HEIGHT))

        pixel_a = bmp.get_pixel(16, 8 + (CELL_HEIGHT * type_row))
        pixel_b = bmp.get_pixel(18, 10 + (CELL_HEIGHT * type_row))
        base_color     = darkenColor(pixel_a, 0.2) || NAME_COLOR    # nombre seleccionado + PP
        base_color_raw = pixel_a                                     # contorno de tipo/categoría (sin oscurecer)
        shadow_color   = darkenColor(pixel_b, 0.2) || SHADOW_COLOR   # sombra del nombre + PP


        pbSetSmallFont(cell)
        pbDrawTextPositions(cell, [[move.name, CELL_WIDTH + (CELL_WIDTH / 2), 14, :center, NAME_COLOR, base_color, :outline]])

        pbSetSystemFont(cell)
        pbDrawTextPositions(cell, [[move.name, CELL_WIDTH / 2, 14, :center, base_color, shadow_color]])

        pbSetSmallFont(cell)
        move_data = GameData::Move.try_get(move.id)
        category  = (move_data && move_data.category.is_a?(Integer)) ? (CATEGORY_NAMES[move_data.category] || "") : ""
        pbDrawTextPositions(cell, [[typename(type), 10, 58, :left, NAME_COLOR, base_color_raw, :outline]])
        pbDrawTextPositions(cell, [[category, CELL_WIDTH - 10, 58, :right, NAME_COLOR, base_color_raw, :outline]])
        pp_text = "#{move.pp}/#{move.total_pp}"
        pbDrawTextPositions(cell, [[pp_text, CELL_WIDTH / 2, 46, :center, base_color, shadow_color]])

        button.bitmap = cell
        button.src_rect.set(CELL_WIDTH, 0, CELL_WIDTH, CELL_HEIGHT)   # por defecto: sin seleccionar
      rescue StandardError => e

        echoln "[EBS FightMenu] boton #{i}: ERROR #{e.class} - #{e.message}"
        @visibility["button_#{i}"] = false
        button.bitmap = nil
      end
    end
  end

  def typename(type)
    name = GameData::Type.get(type).name.upcase
    return name if name.length <= 4
    return name[0, 4]
  end

  def refreshButtonNames
    generateButtons
  end

  def refreshSelection
    moves = (@battler) ? @battler.moves : []
    Pokemon::MAX_MOVES.times do |i|
      button = @sprites["button_#{i}"]
      next if !button || !@visibility["button_#{i}"]
      active = (i == @index)
      # La pareja de columna: 0<->2, 1<->3.
      sibling_i = (i < 2) ? (i + 2) : (i - 2)
      sibling_selected = (sibling_i == @index)
      button.src_rect.x = active ? 0 : CELL_WIDTH
      if active
        target_x, target_local_y = self.x + SELECTED_X[i], SELECTED_Y[i]
      elsif sibling_selected
        target_x, target_local_y = self.x + SIBLING_X[i], SIBLING_Y[i]
      else
        target_x, target_local_y = self.x + REST_X[i], REST_Y[i]
      end
      if @buttons_positioned
        start_button_move(i, button, target_x, target_local_y)
      else

        button.x = target_x
        @btn_local_y[i] = target_local_y
      end
      button.z = self.z + (active ? 4 : 3)
    end
    @buttons_positioned = true
    apply_button_y_offsets
  end

  def start_button_move(i, button, target_x, target_local_y)
    return if button.x == target_x && @btn_local_y[i] == target_local_y && !@btn_anim_start[i]
    @btn_anim_from_x[i]       = button.x
    @btn_anim_from_local_y[i] = @btn_local_y[i] || target_local_y
    @btn_anim_to_x[i]         = target_x
    @btn_anim_to_local_y[i]   = target_local_y
    @btn_anim_start[i]        = System.uptime
  end

  def update_button_anim
    Pokemon::MAX_MOVES.times do |i|
      next if !@btn_anim_start[i]
      button = @sprites["button_#{i}"]
      next if !button
      newX = lerp(@btn_anim_from_x[i], @btn_anim_to_x[i], BUTTON_ANIM_DURATION,
                   @btn_anim_start[i], System.uptime)
      newLocalY = lerp(@btn_anim_from_local_y[i], @btn_anim_to_local_y[i], BUTTON_ANIM_DURATION,
                        @btn_anim_start[i], System.uptime)
      button.x = newX
      @btn_local_y[i] = newLocalY
      @btn_anim_start[i] = nil if newX == @btn_anim_to_x[i] && newLocalY == @btn_anim_to_local_y[i]
    end
    apply_button_y_offsets
  end

  def refreshMegaEvolutionButton
    return if !@megaButton
    @visibility["megaButton"] = (@mode > 0)
    @megaButton.src_rect.y = [@mode - 1, 0].max * 46
    @megaButton.z = self.z + 1
  end

  def refreshShiftButton
  end

  def refresh(refresh_button_names = false)
    return if !@battler
    refreshSelection
    generateButtons if refresh_button_names
    refreshMegaEvolutionButton
    refreshShiftButton
  end
end