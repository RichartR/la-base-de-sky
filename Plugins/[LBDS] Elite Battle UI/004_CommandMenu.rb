
class Battle::Scene::CommandMenu

  alias_method :ebs_nextgen_vanilla_initialize,      :initialize
  alias_method :ebs_nextgen_vanilla_dispose,         :dispose
  alias_method :ebs_nextgen_vanilla_z=,              :z=
  alias_method :ebs_nextgen_vanilla_visible=,        :visible=
  alias_method :ebs_nextgen_vanilla_setTexts,        :setTexts
  alias_method :ebs_nextgen_vanilla_refreshButtons,  :refreshButtons
  alias_method :ebs_nextgen_vanilla_refresh,         :refresh

  EliteBattleUI.import_config(self, EliteBattleUI::CommandMenu)
  include EliteBattleUI::Text::Helpers

  def initialize(viewport, z)
    super(viewport) 
    self.x = 0
    self.y = Graphics.height - MENU_HEIGHT
    @texts = ["", "", "", "", ""]

    @menu_slide_offset_x  = 0
    @menu_logical_visible = nil 
    @menu_slide_start     = nil
    @menu_slide_hiding    = false

    if pbResolveBitmap(GRAPHICS_PATH + "commandMenu")
      @backgroundBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "commandMenu")
      background = Sprite.new(viewport)
      background.bitmap = @backgroundBitmap.bitmap
      background.y = self.y + BACKGROUND_Y_OFFSET
      addSprite("background", background)
    end

    @cmdButtonsBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "cmdButtons")

    @buttons = Array.new(NUM_BUTTONS) do |i|
      button = Sprite.new(viewport)
      addSprite("button_#{i}", button)
      next button
    end


    @messageSprite = Sprite.new(viewport)
    @messageSprite.bitmap = Bitmap.new(Graphics.width, MESSAGE_HEIGHT)
    @messageSprite.y = self.y + MESSAGE_Y_OFFSET
    addSprite("message", @messageSprite)

    self.z = z
    reposition_all
    refresh
  end

  def dispose
    @buttons&.each { |b| b.bitmap.dispose if b.bitmap && !b.bitmap.disposed? }
    @messageSprite.bitmap.dispose if @messageSprite&.bitmap && !@messageSprite.bitmap.disposed?
    super
    @backgroundBitmap&.dispose
    @cmdButtonsBitmap&.dispose
  end

  def z=(value)
    super
    @messageSprite.z = value + 1
    @buttons.each { |b| b.z = value + 2 }
  end

  def reposition_all
    bg = @sprites["background"]
    bg.x = self.x + @menu_slide_offset_x + Graphics.width - @backgroundBitmap.width if bg && @backgroundBitmap
    @messageSprite.x = self.x + @menu_slide_offset_x + 113
    refreshButtons
  end

  def offscreen_menu_offset
    Graphics.width
  end

  def visible=(value)
    if @menu_logical_visible.nil?

      @menu_logical_visible = value
      @menu_slide_offset_x  = value ? 0 : offscreen_menu_offset
      reposition_all
      self.ebs_nextgen_vanilla_visible = value
      return
    end
    return if value == @menu_logical_visible
    @menu_logical_visible = value
    if value && !self.visible

      @menu_slide_offset_x = offscreen_menu_offset
      reposition_all
      self.ebs_nextgen_vanilla_visible = true
    end
    @menu_slide_hiding      = !value
    @menu_slide_from_offset = @menu_slide_offset_x
    @menu_slide_to_offset   = value ? 0 : offscreen_menu_offset
    @menu_slide_start       = System.uptime
  end

  def menu_sliding?
    !@menu_slide_start.nil?
  end

  def tick_menu_slide
    return if !@menu_slide_start
    @menu_slide_offset_x = lerp(@menu_slide_from_offset, @menu_slide_to_offset, MENU_SLIDE_DURATION,
                                @menu_slide_start, System.uptime)
    reposition_all
    return if @menu_slide_offset_x != @menu_slide_to_offset
    self.ebs_nextgen_vanilla_visible = false if @menu_slide_hiding
    @menu_slide_start = nil
  end

  def setTexts(value)
    @texts = value
    refreshMessage
    refreshButtons
  end

  def refreshMessage
    bmp = @messageSprite.bitmap
    bmp.clear
    return if !@texts[0]
    pbSetSmallFont(bmp)

    text = @texts[0].to_s.gsub(/\r?\n/, " ")
    draw_text_with_shadow(bmp, text, bmp.width / 2, 6, :center, MESSAGE_COLOR, MESSAGE_OUTLINE_COLOR)
    pbSetSystemFont(bmp)
  end

  def refreshButtons
    return if !@cmdButtonsBitmap
    bmp = @cmdButtonsBitmap.bitmap
    x_cursor = self.x + @menu_slide_offset_x + BUTTONS_START_X
    NUM_BUTTONS.times do |i|
      button = @sprites["button_#{i}"]
      next if !button
      active = (i == @index)
      w = active ? CELL_WIDTH : COLLAPSED_WIDTH
      button.bitmap.dispose if button.bitmap && !button.bitmap.disposed?
      cell = Bitmap.new(w, CELL_HEIGHT)
      if active
        cell.blt(0, 0, bmp, Rect.new(0, CELL_HEIGHT * i, CELL_WIDTH, CELL_HEIGHT))
        pbSetSmallFont(cell)
        outline = darkenColor(bmp.get_pixel(52, 22 + (CELL_HEIGHT * i)), 0.6) || OUTLINE_COLOR
        label = @texts[i + 1] || ""
        pbDrawTextPositions(cell, [[label, w / 2, BUTTON_TEXT_Y, :center, TEXT_COLOR, outline, :outline]])
      else
        cell.blt(0, 0, bmp, Rect.new(CELL_WIDTH, CELL_HEIGHT * i, COLLAPSED_WIDTH, CELL_HEIGHT))
      end
      button.bitmap = cell
      button.x = x_cursor
      button.y = self.y + BUTTON_Y_OFFSET
      button.z = self.z + (active ? 3 : 2)
      x_cursor += w
    end
  end

  def refresh
    refreshMessage
    refreshButtons
  end
end


#===============================================================================
# Navegación del menú
#===============================================================================

class Battle::Scene
  alias_method :ebs_nextgen_vanilla_pbCommandMenuEx, :pbCommandMenuEx

  def pbCommandMenuEx(idxBattler, texts, mode = 0)
    pbRefreshUIPrompt(idxBattler, COMMAND_BOX) if respond_to?(:pbRefreshUIPrompt)

    cw = @sprites["commandWindow"]
    cw.setTexts(texts)
    cw.setIndexAndMode(@lastCmd[idxBattler], mode)
    pbShowWindow(COMMAND_BOX)
    pbSelectBattler(idxBattler)
    ret = -1
    mouseState = pbInitializeMouseState
    promptTimer = System.uptime if respond_to?(:pbShowingPrompt?)
    loop do
      oldIndex = cw.index
      pbUpdate(cw)

      if respond_to?(:pbShowingPrompt?) && Settings::UI_PROMPT_DISPLAY == 2 && pbShowingPrompt?
        pbToggleUIPrompt if System.uptime - promptTimer > 2
      end

      if Input.trigger?(Input::LEFT)
        cw.index = (cw.index - 1) % 4
      elsif Input.trigger?(Input::RIGHT)
        cw.index = (cw.index + 1) % 4
      end
      pbPlayCursorSE if cw.index != oldIndex

      clickedIndex = pbCheckMouseButtons(cw.buttons, mouseState)
      if clickedIndex
        cw.index = clickedIndex
        pbPlayDecisionSE
        ret = cw.index
        @lastCmd[idxBattler] = ret
        break
      end

      # Acciones
      if Input.trigger?(Input::USE)                 # Confirmar
        pbPlayDecisionSE
        ret = cw.index
        @lastCmd[idxBattler] = ret
        break
      elsif Input.trigger?(Input::BACK) && mode == 1   # Cancelar
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::F9) && $DEBUG    # Menú de depuración
        pbPlayDecisionSE
        pbHideInfoUI if respond_to?(:pbHideInfoUI)
        ret = -2
        break
      elsif respond_to?(:pbToggleBattleInfo) && Input.trigger?(Input::JUMPUP) && !pbInSafari?
        # Abre/cierra el Battler Info UI del DBK.
        pbToggleBattleInfo
        promptTimer = System.uptime
      elsif respond_to?(:pbToggleBallInfo) && Input.trigger?(Input::JUMPDOWN) && !pbInSafari?
        if pbToggleBallInfo(idxBattler)
          ret = 1
          @lastCmd[idxBattler] = ret
          break
        end
        promptTimer = System.uptime
      end
    end
    return ret
  end
end