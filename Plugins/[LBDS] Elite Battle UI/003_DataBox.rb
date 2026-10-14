#===============================================================================
class Battle::Scene::PokemonDataBox < Sprite
  alias_method :ebs_nextgen_vanilla_initialize,               :initialize
  alias_method :ebs_nextgen_vanilla_initializeDataBoxGraphic, :initializeDataBoxGraphic
  alias_method :ebs_nextgen_vanilla_dispose,                  :dispose
  alias_method :ebs_nextgen_vanilla_x=,                       :x=
  alias_method :ebs_nextgen_vanilla_y=,                       :y=
  alias_method :ebs_nextgen_vanilla_z=,                       :z=
  alias_method :ebs_nextgen_vanilla_opacity=,                 :opacity=
  alias_method :ebs_nextgen_vanilla_visible=,                 :visible=
  alias_method :ebs_nextgen_vanilla_color=,                   :color=
  alias_method :ebs_nextgen_vanilla_battler=,                 :battler=
  alias_method :ebs_nextgen_vanilla_refresh,                  :refresh
  alias_method :ebs_nextgen_vanilla_update,                   :update

  attr_reader   :battler
  attr_accessor :selected


  @@player_databox_unlocked = false

  def self.unlock_player_databox!
    @@player_databox_unlocked = true
  end

  def self.player_databox_unlocked?
    @@player_databox_unlocked
  end

  EliteBattleUI.import_config(self, EliteBattleUI::DataBox)
  include EliteBattleUI::Text::Helpers

  def initialize(battler, sideSize, viewport = nil)
    super(viewport)

    @@player_databox_unlocked = false
    @battler          = battler
    @sprites          = {}
    @spriteX          = 0
    @spriteY          = 0
    @selected         = 0
    @player_side      = @battler.index.even?
    @show_hp_text     = false
    @show_hp_percent  = false
    @show_exp_bar     = false
    @mega_icon_name   = nil
    @mega_breathe     = 1
    @charged          = false
    @slide_timer_start = nil 
    @slide_hiding       = false
    initializeDataBoxGraphic(sideSize)
    initializeOtherGraphics(viewport)
    refresh
  end


  def getBattler(battler)
    if PBEffects.const_defined?(:Illusion) && battler.respond_to?(:effects) &&
       !battler.effects[PBEffects::Illusion].nil?
      return battler.effects[PBEffects::Illusion]
    end
    return battler
  end

  #=============================================================================
  # Posicionamiento
  #=============================================================================
  def initializeDataBoxGraphic(sideSize)
    @show_hp_text    = @player_side && (sideSize == 1)
    @show_hp_percent = !@player_side && Settings::SHOW_ENEMY_HP_PERCENTAGE && sideSize < 3
    @show_exp_bar    = @player_side && (sideSize == 1)
    @pending_side_size = sideSize
    if @layer1Bitmap
      finalizePosition
      applyCollapsedHeight
    end
  end

  def finalizePosition
    sideSize = @pending_side_size || 1
    w = @layer1Bitmap.width
    h = @layer1Bitmap.height
    if @player_side
      @spriteX = PLAYER_X_MARGIN
      @spriteY = Graphics.height - h - PLAYER_Y_MARGIN
    else
      @spriteX = Graphics.width - w - FOE_X_MARGIN 
      @spriteY = FOE_Y_MARGIN
    end
    case sideSize
    when 1
      @spriteX += @player_side ? SINGLES_X_SHIFT : -SINGLES_X_SHIFT
    when 2
      if @player_side
        @spriteX += SIDE_2_X_OFFSETS[@battler.index]
        @spriteY += SIDE_2_Y_OFFSETS[@battler.index]
      else
        zone_center = (@battler.index == 1) ? (Graphics.width * 3 / 4) : (Graphics.width / 4)
        @spriteX = zone_center - (w / 2) - 2
        @spriteY += SIDE_2_Y_OFFSETS[@battler.index]
      end
    when 3
      @spriteX += SIDE_3_X_OFFSETS[@battler.index]
      @spriteY += SIDE_3_Y_OFFSETS[@battler.index]
    end
  end

  def applyCollapsedHeight
    return if !@layer1
    if @show_exp_bar
      @layer1.src_rect.height = @layer1Bitmap.height
      @shadow.src_rect.height = @layer1Bitmap.height
    else
      @layer1.src_rect.height = [COLLAPSED_BOX_HEIGHT, @layer1Bitmap.height].min
      @shadow.src_rect.height = [COLLAPSED_BOX_HEIGHT, @layer1Bitmap.height].min
    end
  end

  def initializeOtherGraphics(viewport)
    @layer1Bitmap = AnimatedBitmap.new(GRAPHICS_PATH + "layer1")
    @layer2Bitmap = AnimatedBitmap.new(GRAPHICS_PATH + "layer2") if pbResolveBitmap(GRAPHICS_PATH + "layer2")
    @hpBarBitmap  = AnimatedBitmap.new(GRAPHICS_PATH + "hpBar")
    @hpBarChargedBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "hpBarCharged") if pbResolveBitmap(GRAPHICS_PATH + "hpBarCharged")
    @expBarBitmap = AnimatedBitmap.new(GRAPHICS_PATH + "expBar")

    finalizePosition

  
    @layer1 = Sprite.new(viewport)
    @layer1.bitmap = @layer1Bitmap.bitmap
    @layer1.mirror = !@player_side
    @sprites["layer1"] = @layer1

    @shadow = Sprite.new(viewport)
    @shadow.bitmap = Bitmap.new(@layer1Bitmap.width, @layer1Bitmap.height)
    @shadow.bitmap.blt(0, 0, @layer1Bitmap.bitmap, Rect.new(0, 0, @layer1Bitmap.width, @layer1Bitmap.height))
    @shadow.mirror = !@player_side
    @shadow.color  = Color.new(0, 0, 0, 255)
    @sprites["shadow"] = @shadow

    applyCollapsedHeight

    @hpBar = Sprite.new(viewport)
    @hpBar.bitmap = Bitmap.new(@hpBarBitmap.width, @hpBarBitmap.height)
    @hpBar.mirror = !@player_side
    @sprites["hpBar"] = @hpBar


    @expBar = Sprite.new(viewport)
    @expBar.bitmap = @expBarBitmap.bitmap
    @sprites["expBar"] = @expBar


    @mega = Sprite.new(viewport)
    @mega.opacity = 0
    @sprites["mega"] = @mega


    @charge_sparkles = []
    CHARGE_SEGMENT_COUNT.times do |i|
      spr = Sprite.new(viewport)
      spr.bitmap = Bitmap.new(4, 14)
      spr.visible = false
      spr.z = DATABOX_BASE_Z + 2
      @sprites["chr#{i}"] = spr
      @charge_sparkles << spr
    end

    @hpTextSprite = Sprite.new(viewport)
    @hpTextSprite.bitmap = Bitmap.new(@layer1Bitmap.width, HP_TEXT_SPRITE_HEIGHT)
    @sprites["hpText"] = @hpTextSprite

    pbSetSmallFont(@hpTextSprite.bitmap)
    @hpTextSprite.bitmap.draw_text(0, 0, @hpTextSprite.bitmap.width, HP_TEXT_SPRITE_HEIGHT, "888/888")
    @hpTextSprite.bitmap.clear

    @hpTextSprite.x = @spriteX
    @hpTextSprite.y = @spriteY + HP_TEXT_Y

    @hpTextSprite.z = DATABOX_BASE_Z + ((@battler.index / 2) * 5) + 10

    @contents = Bitmap.new(@layer1Bitmap.width, @layer1Bitmap.height)
    self.bitmap  = @contents
    self.visible = false
    self.z       = DATABOX_BASE_Z + ((@battler.index / 2) * 5)
    pbSetSystemFont(self.bitmap)

    self.x = @spriteX
    self.y = @spriteY

    self.opacity = 255
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @layer1Bitmap.dispose
    @layer2Bitmap&.dispose
    @hpBarBitmap.dispose
    @hpBarChargedBitmap&.dispose
    @expBarBitmap.dispose
    @hpBar.bitmap.dispose if @hpBar&.bitmap && !@hpBar.bitmap.disposed?
    @shadow.bitmap.dispose if @shadow&.bitmap && !@shadow.bitmap.disposed?
    @hpTextSprite.bitmap.dispose if @hpTextSprite&.bitmap && !@hpTextSprite.bitmap.disposed?
    @megaBitmap&.dispose
    @contents.dispose
    super
  end


  def x=(value)
    super
    @layer1.x = value
    @shadow.x = value + SHADOW_OFFSET_X
    @hpBar.x  = value + HP_BAR_X + ((!@player_side) ? HP_BAR_FOE_EXTRA_X : 0)
    @expBar.x = value + EXP_BAR_X
    @mega.x   = value + (@player_side ? MEGA_ICON_PLYR_X : MEGA_ICON_FOE_X)
 
    @hpTextSprite.x = value if @hpTextSprite
  end

  def y=(value)

    actual = @spriteY
    super(actual)
    @layer1.y = actual
    @shadow.y = actual + SHADOW_OFFSET_Y
    @hpBar.y  = actual + HP_BAR_Y
    @expBar.y = actual + EXP_BAR_Y
    @mega.y   = actual + MEGA_ICON_Y

  end

  def z=(value)
    super 
    @shadow.z = value - 4
    @layer1.z = value - 3
    @hpBar.z  = value - 1
    @expBar.z = value - 1
    @mega.z   = value - 1
    @charge_sparkles.each { |spr| spr.z = value - 1 if !spr.disposed? }
  end

  def opacity=(value)
    super
    @sprites.each do |key, sprite|
      next if sprite.disposed?
      next if key.start_with?("chr") 
      sprite.opacity = (key == "shadow") ? (value * 0.25).to_i : value
    end
  end

  def visible=(value)
    value = false if @player_side && value && !self.class.player_databox_unlocked?
    super
    @sprites.each do |key, sprite|
      next if sprite.disposed?
      next if key.start_with?("chr")
      sprite.visible = value
    end
    @charge_sparkles.each { |spr| spr.visible = (value && @charged) if !spr.disposed? }
    @expBar.visible = (value && @show_exp_bar)
    @mega.visible   = (value && @mega_icon_name != nil)
  end

  def color=(value)
    super
    @sprites.each { |_key, sprite| sprite.color = value if !sprite.disposed? }
  end

  def pbRevealSliding
    return if !@player_side
    return if self.visible && @slide_timer_start.nil?
    if !self.visible

      self.x = offscreen_slide_x
      self.visible = true
    end
    @slide_hiding       = false
    @slide_start_x      = self.x
    @slide_target_x     = @spriteX
    @slide_timer_start  = System.uptime
  end

  def pbHideSliding
    return if !@player_side
    return if !self.visible && @slide_timer_start.nil?
    @slide_hiding      = true
    @slide_start_x     = self.x
    @slide_target_x    = offscreen_slide_x
    @slide_timer_start = System.uptime
  end

  def offscreen_slide_x
    width = @layer1Bitmap ? @layer1Bitmap.width : REVEAL_SLIDE_DISTANCE
    @spriteX - width - REVEAL_SLIDE_MARGIN
  end

  def update_reveal_slide
    return if !@slide_timer_start
    newX = lerp(@slide_start_x, @slide_target_x, REVEAL_SLIDE_DURATION,
                @slide_timer_start, System.uptime)
    self.x = newX
    return if newX != @slide_target_x
    self.visible = false if @slide_hiding
    @slide_timer_start = nil
  end

  def battler=(b)
    @battler = b
    self.visible = (@battler && !@battler.fainted?)
  end

  #=============================================================================
  # HP / EXP
  #=============================================================================
  def hp
    return (animating_hp?) ? @anim_hp_current : @battler.hp
  end

  def exp_fraction
    return 0.0 if !@battler.pokemon
    if animating_exp?
      return 0.0 if @anim_exp_range == 0
      return @anim_exp_current.to_f / @anim_exp_range
    end
    return @battler.pokemon.exp_fraction
  end

  def animate_hp(old_val, new_val)
    return if old_val == new_val
    @anim_hp_start       = old_val
    @anim_hp_end         = new_val
    @anim_hp_current     = old_val
    @anim_hp_timer_start = System.uptime
  end

  def animating_hp?
    return !@anim_hp_timer_start.nil?
  end

  def animate_exp(old_val, new_val, range)
    return if old_val == new_val || range == 0 || !@show_exp_bar
    @anim_exp_start          = old_val
    @anim_exp_end            = new_val
    @anim_exp_range          = range
    @anim_exp_duration_mult  = (new_val - old_val).abs / range.to_f
    @anim_exp_current        = old_val
    @anim_exp_timer_start    = System.uptime
    pbSEPlay("Pkmn exp gain")
  end

  def animating_exp?
    return !@anim_exp_timer_start.nil?
  end

  def update_hp_animation
    return if !animating_hp?
    @anim_hp_current = lerp(@anim_hp_start, @anim_hp_end, HP_BAR_CHANGE_TIME,
                             @anim_hp_timer_start, System.uptime)
    refresh_hp
    return if @anim_hp_current != @anim_hp_end
    @anim_hp_start = nil
    @anim_hp_end = nil
    @anim_hp_timer_start = nil
    @anim_hp_current = nil
  end

  def update_exp_animation
    return if !animating_exp?
    if !@show_exp_bar
      @anim_exp_timer_start = nil
      return
    end
    duration = EXP_BAR_FILL_TIME * @anim_exp_duration_mult
    @anim_exp_current = lerp(@anim_exp_start, @anim_exp_end, duration,
                              @anim_exp_timer_start, System.uptime)
    refresh_exp
    return if @anim_exp_current != @anim_exp_end
    if @anim_exp_current >= @anim_exp_range
      if @anim_exp_flash_timer_start
        return if System.uptime - @anim_exp_flash_timer_start < EXP_FULL_FLASH_DURATION
      else
        @anim_exp_flash_timer_start = System.uptime
        pbSEStop
        pbSEPlay("Pkmn exp full")
        flash_duration = EXP_FULL_FLASH_DURATION * Graphics.frame_rate
        self.flash(Color.new(64, 200, 248, 192), flash_duration)
        @sprites.each { |_k, sprite| sprite.flash(Color.new(64, 200, 248, 192), flash_duration) if !sprite.disposed? }
        return
      end
    end
    pbSEStop if !@anim_exp_flash_timer_start
    @anim_exp_start = nil
    @anim_exp_end = nil
    @anim_exp_duration_mult = nil
    @anim_exp_current = nil
    @anim_exp_timer_start = nil
    @anim_exp_flash_timer_start = nil
  end

  #=============================================================================
  # Barra de HP "cargada" (chispas)
  #=============================================================================
  def charge
    @charged = true
    refresh_hp
    self.visible = self.visible
  end

  def stopCharge
    @charged = false
    refresh_hp
    self.visible = self.visible
  end

  def charged?
    return @charged
  end

  def updateChargeAnimation
    return if !@charged || !self.visible
    CHARGE_SEGMENT_COUNT.times do |i|
      spr = @charge_sparkles[i]
      next if spr.disposed?
      if spr.zoom_y >= 1.0
        spr.zoom_y  = 0
        spr.opacity = 255
      end
      spr.opacity -= 256 / 48.0
      spr.zoom_y  += 1.0 / 24.0
      spr.x = @hpBar.x + 2 + (i * 4)
      spr.y = @hpBar.y + 2
      spr.visible = true
    end
  end

  #=============================================================================
  # Dibujado
  #=============================================================================
  def draw_name
    display = getBattler(@battler)
    name_x = @player_side ? NAME_PLYR_X : NAME_FOE_X
    width = self.bitmap.text_size(display.name).width
    name_x -= (width - NAME_MAX_WIDTH) if width > NAME_MAX_WIDTH
    shiny = display.respond_to?(:shiny?) ? display.shiny? : false
    color = shiny ? NAME_SHINY_COLOR : NAME_BASE_COLOR
    draw_text_with_shadow(self.bitmap, display.name, name_x, NAME_Y, :left, color, NAME_SHADOW_COLOR)
  end

  def draw_level
    display = getBattler(@battler)
    pbSetSmallFont(self.bitmap)
    prefix = _INTL("Nv.")
    prefix_width = self.bitmap.text_size(prefix).width
    number = display.level.to_s
    number_width = self.bitmap.text_size(number).width
    # Todo el bloque "Nv.100" queda alineado a la derecha, pegado al borde
    # derecho de la placa (más robusto que un x fijo, ya sea nivel 5 o 100).
    number_x = LEVEL_X_FROM_RIGHT - number_width
    prefix_x = number_x - prefix_width - 2
    draw_text_with_shadow(self.bitmap, prefix, prefix_x, LEVEL_Y, :left, LEVEL_PREFIX_COLOR, LEVEL_SHADOW_COLOR)
    draw_text_with_shadow(self.bitmap, number, number_x, LEVEL_Y, :left, LEVEL_BASE_COLOR, LEVEL_SHADOW_COLOR)
    pbSetSystemFont(self.bitmap)
  end

  def draw_gender
    display = getBattler(@battler)
    gender = display.respond_to?(:displayGender) ? display.displayGender : nil
    return if ![0, 1].include?(gender)
    text  = (gender == 0) ? _INTL("♂") : _INTL("♀")
    color = (gender == 0) ? MALE_BASE_COLOR : FEMALE_BASE_COLOR
    gender_x = (@player_side ? NAME_PLYR_X : NAME_FOE_X) + self.bitmap.text_size(display.name).width + 4
    draw_text_with_shadow(self.bitmap, text, gender_x, GENDER_Y, :left, color, GENDER_SHADOW_COLOR)
  end

  def draw_status
    return if @battler.status == :NONE
    s = GameData::Status.get(@battler.status).icon_position
    return if s < 0
    icon_path = EliteBattleUI.resolve_graphic("Graphics/UI/Battle/icon_statuses")
    pbDrawImagePositions(self.bitmap, [[icon_path, STATUS_ICON_X, STATUS_ICON_Y,
                                         0, s * STATUS_ICON_HEIGHT, -1, STATUS_ICON_HEIGHT]])
  end

  def draw_owned_icon
    return if @player_side
    return if !@battler.owned?
    return if @battler.battle.trainerBattle?   # el original solo lo mostraba en combates salvajes
    pbDrawImagePositions(self.bitmap, [[EliteBattleUI.resolve_graphic("Graphics/UI/Battle/icon_own"), OWNED_ICON_X, OWNED_ICON_Y]])
  end

  def draw_hp_text
    return if !@hpTextSprite
    @hpTextSprite.bitmap.clear   # se limpia SIEMPRE, en cada llamada, sin
                                 # tocar nombre/nivel/género — esto es lo
                                 # que evita el rastro de números/sombras.
    if !@show_hp_text && !@show_hp_percent
      return
    end
    if @show_hp_percent
      pct = (@battler.totalhp > 0) ? ((self.hp / @battler.totalhp.to_f) * 100).ceil.to_i : 0
      text = _INTL("{1}%", pct)
    else

      text = _INTL("{1}/{2}", self.hp.round, @battler.totalhp)
    end
    bmp = @hpTextSprite.bitmap
    pbSetSmallFont(bmp) 
    draw_text_with_shadow(bmp, text, bmp.width / 2, 6, :center, HP_TEXT_BASE_COLOR, HP_TEXT_SHADOW_COLOR)
  end

  def refresh_mega_icon
    name = nil
    if @battler.mega?
      name = "Graphics/UI/Battle/icon_mega"
    elsif @battler.respond_to?(:primal?) && @battler.primal?
      name = "Graphics/UI/Battle/icon_primal_Groudon" if @battler.isSpecies?(:GROUDON)
      name = "Graphics/UI/Battle/icon_primal_Kyogre" if @battler.isSpecies?(:KYOGRE)
    end
    name = EliteBattleUI.resolve_graphic(name) if name
    return if name == @mega_icon_name
    @mega_icon_name = name
    @megaBitmap&.dispose
    if name && pbResolveBitmap(name)
      @megaBitmap = AnimatedBitmap.new(name)
      @mega.bitmap = @megaBitmap.bitmap
      @mega.tone   = Tone.new(0, 0, 0)
      @mega.visible = self.visible
    else
      @megaBitmap = nil
      @mega.bitmap = nil
      @mega.visible = false
    end
  end

  def refresh_hp
    return if !@battler.pokemon
    draw_hp_text
    px = (@battler.totalhp == 0) ? 0 : (1.0 * self.hp * @hpBarBitmap.width / @battler.totalhp).ceil
    px = px.clamp(0, @hpBarBitmap.width)
    @hpBar.bitmap.clear
    bmp = (@charged && @hpBarChargedBitmap) ? @hpBarChargedBitmap.bitmap : @hpBarBitmap.bitmap
    @hpBar.bitmap.blt(0, 0, bmp, Rect.new(0, 0, bmp.width, bmp.height))
    if !@charged
      hue = -120 * (1.0 - (@battler.totalhp > 0 ? self.hp.to_f / @battler.totalhp : 0))
      @hpBar.bitmap.hue_change(hue)
    end
    @hpBar.src_rect.width = px
    @hpBar.src_rect.x = (@player_side) ? 0 : @hpBarBitmap.width - px
  end

  def refresh_exp
    return if !@show_exp_bar
    @expBar.src_rect.width = (exp_fraction * @expBarBitmap.width).round
  end

  def refresh
    self.bitmap.clear
    @layer2Bitmap&.tap do |bmp|
      h = @show_exp_bar ? bmp.height : [COLLAPSED_BOX_HEIGHT, bmp.height].min
      self.bitmap.blt(0, 0, bmp.bitmap, Rect.new(0, 0, bmp.width, h))
    end
    return if !@battler.pokemon
    draw_name
    draw_level
    draw_gender
    draw_status
    draw_owned_icon
    refresh_hp
    refresh_exp
    refresh_mega_icon
  end

  #=============================================================================
  # Actualización por fotograma
  #=============================================================================
  def update_positions
    self.x = @spriteX
    self.y = @spriteY
  end

  def update_mega_glow
    return if !(@battler.mega? || (@battler.respond_to?(:primal?) && @battler.primal?))
    @mega.tone.red   += @mega_breathe
    @mega.tone.green += @mega_breathe
    @mega.tone.blue  += @mega_breathe
    @mega_breathe = -1 if @mega.tone.red >= 100
    @mega_breathe = 1  if @mega.tone.red <= 0
  end

  def update
    super
    update_hp_animation
    update_exp_animation
    update_positions
    updateChargeAnimation
    update_mega_glow
    update_reveal_slide
    pbUpdateSpriteHash(@sprites)
  end
end


class Battle::Scene::Animation::DataBoxAppear
  alias_method :ebs_nextgen_vanilla_createProcesses, :createProcesses

  def createProcesses
    return if !@sprites["dataBox_#{@idxBox}"]
    box = addSprite(@sprites["dataBox_#{@idxBox}"])
    box.setVisible(0, true)
    dir = (@idxBox.even?) ? -1 : 1   # volteado: jugador entra por la izquierda, rival por la derecha
    box.setDelta(0, dir * Graphics.width / 2, 0)
    box.moveDelta(0, 8, -dir * Graphics.width / 2, 0)
  end
end

class Battle::Scene
  alias_method :ebs_nextgen_databox_vanilla_pbShowWindow, :pbShowWindow

  def pbShowWindow(windowType)
    ebs_nextgen_databox_vanilla_pbShowWindow(windowType)
    Battle::Scene::PokemonDataBox.unlock_player_databox! if windowType == COMMAND_BOX
  end
end