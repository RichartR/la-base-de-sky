#===============================================================================
#  Elite Battle UI
#  ARCHIVO DE CONFIGURACIÓN GLOBAL
#===============================================================================
module EliteBattleUI
  GRAPHICS_PATH = "Graphics/Plugins/EliteBattleUI/"
  module Text
    BASE_COLOR              = Color.new(255, 255, 255)
    SHADOW_COLOR            = Color.new(40, 40, 40)
    GOLD_COLOR              = Color.new(222, 197, 95)   # nombre shiny / prefijo de nivel
    SHADOW_DUPLICATE_COLOR  = Color.new(0, 0, 0, (255 * 0.30).round)
    SHADOW_DUPLICATE_OFFSET = 2
    module Helpers
      def draw_text_with_shadow(bitmap, text, x, y, align, color, contour_color)
        pbDrawTextPositions(bitmap, [[text, x + SHADOW_DUPLICATE_OFFSET, y + SHADOW_DUPLICATE_OFFSET,
                                       align, SHADOW_DUPLICATE_COLOR, SHADOW_DUPLICATE_COLOR]])
        pbDrawTextPositions(bitmap, [[text, x, y, align, color, contour_color, :outline]])
      end

      def darkenColor(color = nil, amt = 0.2)
        return nil if color.nil?
        red   = color.red   - (color.red   * amt)
        green = color.green - (color.green * amt)
        blue  = color.blue  - (color.blue  * amt)
        return Color.new(red, green, blue)
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Data Box
  #-----------------------------------------------------------------------------
  module DataBox
    GRAPHICS_PATH = EliteBattleUI::GRAPHICS_PATH

    # Tiempos de animación
    EXP_BAR_FILL_TIME       = 1.75  
    EXP_FULL_FLASH_DURATION = 0.2  
    HP_BAR_CHANGE_TIME      = 1.0    
    BOBBING_DURATION        = 0.6
    CHARGE_SEGMENT_COUNT    = 46
    COLLAPSED_BOX_HEIGHT    = 64

    DATABOX_BASE_Z = 150
    HP_TEXT_SPRITE_HEIGHT = 32

    NAME_BASE_COLOR      = Text::BASE_COLOR
    NAME_SHADOW_COLOR    = Text::SHADOW_COLOR
    NAME_SHINY_COLOR     = Text::GOLD_COLOR   # nombre en dorado si el Pokémon es shiny
    MALE_BASE_COLOR      = Color.new(48, 96, 216)
    FEMALE_BASE_COLOR    = Color.new(248, 88, 40)
    GENDER_SHADOW_COLOR  = Text::SHADOW_COLOR
    LEVEL_BASE_COLOR     = Text::BASE_COLOR
    LEVEL_SHADOW_COLOR   = Text::SHADOW_COLOR
    LEVEL_PREFIX_COLOR   = Text::GOLD_COLOR
    HP_TEXT_BASE_COLOR   = Text::BASE_COLOR
    HP_TEXT_SHADOW_COLOR = Text::SHADOW_COLOR
    SHADOW_DUPLICATE_COLOR  = Text::SHADOW_DUPLICATE_COLOR
    SHADOW_DUPLICATE_OFFSET = Text::SHADOW_DUPLICATE_OFFSET
    PLAYER_X_MARGIN = 4
    PLAYER_Y_MARGIN = 4
    FOE_X_MARGIN    = 4
    FOE_Y_MARGIN    = -6
    SINGLES_X_SHIFT = 22
    # Desplazamientos extra en dobles/triples
    SIDE_2_X_OFFSETS = [-24, -22, -4, -304]
    SIDE_2_Y_OFFSETS = [-58, 0, 12, 0]
    SIDE_3_X_OFFSETS = [-22, 0, -7, -130, 8, -260]
    SIDE_3_Y_OFFSETS = [-66, 0, -21, 47, 24, 0]
    HP_BAR_X           = 28
    HP_BAR_FOE_EXTRA_X = 4
    HP_BAR_Y           = 46
    EXP_BAR_X          = 40
    EXP_BAR_Y          = 68
    SHADOW_OFFSET_X    = 2   # sombra proyectada de la caja (no confundir con la del texto)
    SHADOW_OFFSET_Y    = 2
    MEGA_ICON_PLYR_X   = 221
    MEGA_ICON_FOE_X    = -8
    MEGA_ICON_Y        = 40

    NAME_PLYR_X        = 36
    NAME_FOE_X         = 36
    NAME_Y             = 22
    NAME_MAX_WIDTH     = 110
    LEVEL_X_FROM_RIGHT = 220
    LEVEL_Y            = 22
    GENDER_Y           = 22
    STATUS_ICON_X      = 34
    STATUS_ICON_Y      = 54
    STATUS_ICON_HEIGHT = 16
    OWNED_ICON_X       = 34
    OWNED_ICON_Y       = 54
    HP_TEXT_Y          = 54
    REVEAL_SLIDE_DISTANCE = 250 
    REVEAL_SLIDE_MARGIN   = 24 
    REVEAL_SLIDE_DURATION = 0.28
  end

  #-----------------------------------------------------------------------------
  # Command Menu (Luchar / Mochila / Pokémon / Huir)
  #-----------------------------------------------------------------------------
  module CommandMenu
    GRAPHICS_PATH = EliteBattleUI::GRAPHICS_PATH

    CELL_WIDTH      = 98
    CELL_HEIGHT     = 44
    COLLAPSED_WIDTH = 22
    NUM_BUTTONS     = 4

    BUTTONS_START_X = 328
    BUTTON_Y_OFFSET = 16
    BUTTON_TEXT_Y   = 14
    BACKGROUND_Y_OFFSET = 19
    MESSAGE_Y_OFFSET = 64
    MESSAGE_HEIGHT   = 32

    TEXT_COLOR    = Text::BASE_COLOR
    OUTLINE_COLOR = Color.new(0, 0, 0)
    MESSAGE_COLOR = Text::BASE_COLOR
    MESSAGE_OUTLINE_COLOR = Text::SHADOW_COLOR
    SHADOW_DUPLICATE_COLOR  = Text::SHADOW_DUPLICATE_COLOR
    SHADOW_DUPLICATE_OFFSET = Text::SHADOW_DUPLICATE_OFFSET
    MENU_SLIDE_DURATION = 0.22
  end

  #-----------------------------------------------------------------------------
  # Fight Menu
  #-----------------------------------------------------------------------------
  module FightMenu
    GRAPHICS_PATH = EliteBattleUI::GRAPHICS_PATH

    CELL_WIDTH  = 198
    CELL_HEIGHT = 78

    # Posiciones en pantalla de cada una de las 4 cajas de movimientos
    REST_X     = [58, 258, 58, 258]
    SELECTED_X = [58, 258, 58, 258]
    SIBLING_X  = [58, 258, 58, 258]

    REST_Y = [
      248 + 44,   # 0 arriba-izq en reposo
      248 + 44,   # 1 arriba-der en reposo
      292 + 46,   # 2 abajo-izq en reposo
      292 + 46,   # 3 abajo-der en reposo
    ]
    SELECTED_Y = [
      258,        # 0 arriba-izq — CUANDO está seleccionada
      258,        # 1 arriba-der — CUANDO está seleccionada
      326 - 20,   # 2 abajo-izq  — CUANDO está seleccionada
      326 - 20,   # 3 abajo-der  — CUANDO está seleccionada
    ]
    SIBLING_Y = [
      282 - 20,   # 0 arriba-izq — cuando  (2, su pareja de abajo) está seleccionada
      282 - 20,   # 1 arriba-der — cuando  (3, su pareja de abajo) está seleccionada
      346 - 8,    # 2 abajo-izq  — cuando  (0, su pareja de arriba) está seleccionada
      346 - 8,    # 3 abajo-der  — cuando  (1, su pareja de arriba) está seleccionada
    ]

    NAME_COLOR   = Text::BASE_COLOR
    PP_COLOR     = Text::BASE_COLOR
    SHADOW_COLOR = Text::SHADOW_COLOR
    SHADOW_DUPLICATE_COLOR  = Text::SHADOW_DUPLICATE_COLOR
    SHADOW_DUPLICATE_OFFSET = Text::SHADOW_DUPLICATE_OFFSET

    # Nombres de categoría (Físico/Especial/Estado)
    CATEGORY_NAMES = [_INTL("Fis"), _INTL("Esp"), _INTL("Est")]

    MENU_SLIDE_DURATION  = 0.22
    MENU_SLIDE_DISTANCE  = 200
    BUTTON_ANIM_DURATION = 0.15
  end

  #-----------------------------------------------------------------------------
  # Caja de mensaje de combate
  #-----------------------------------------------------------------------------
  module MessageBox
    GRAPHICS_PATH = EliteBattleUI::GRAPHICS_PATH
    BASE_COLOR   = Text::BASE_COLOR
    SHADOW_COLOR = Text::SHADOW_COLOR
    CRITICAL_BASE_COLOR   = Color.new(255, 145, 40)
    CRITICAL_SHADOW_COLOR = Color.new(90, 40, 10)
  end

  #-----------------------------------------------------------------------------
  # Iconos de Z-Move / Ultra Burst / Dynamax / Terastalización
  #-----------------------------------------------------------------------------
  module SpecialButtons
    GRAPHICS_PATH = EliteBattleUI::GRAPHICS_PATH
    CURSOR_FILES = {
      zmove:   "cursor_zmove",
      ultra:   "cursor_ultra",
      dynamax: "cursor_dynamax",
      tera:    "cursor_tera",
    }
  end
  module BattleLayout
    PLAYER_SPRITE_Y_OFFSET = 96   # sprite trasero del jugador (pbCreateTrainerBackSprite)
    PLAYER_BASE_Y_OFFSET   = 50   # base gráfica bajo el jugador (pbCreateBackdropSprites)
  end

  def self.import_config(into, from)
    from.constants.each do |const_name|
      into.const_set(const_name, from.const_get(const_name))
    end
  end

  def self.resolve_graphic(vanilla_path)
    filename = vanilla_path.to_s.split("/").last
    nextgen_path = GRAPHICS_PATH + filename
    return pbResolveBitmap(nextgen_path) ? nextgen_path : vanilla_path
  end
end

#===============================================================================
#  Cámara dinámica de combate (EBS Camera)
#===============================================================================

module EBSCamera
  ENABLED  = true
  INC      = 0.20
  INC_FAST = 0.40
  MENU_DURATION = 21
  FAINT_DURATION = 32
  IDLE_DELAY = 8
  IDLE_DELAY_FIRST = 1.0

  SENDOUTVECTOR1 = [-45, 16, -3, -28, 0, 0]
  SENDOUTVECTOR2 = [-28, 10, -1, -14, 0, 0]
  ENEMYVECTOR    = [-48, 18, -3,  22, 0, 0]
  PLAYERVECTOR   = [ 48,-18,  3,  22, 0, 0]
  DUALVECTOR     = [  0,  0,  0,  35, 0, 0]
  UPPER_RIGHT    = [ 36,-14,  0, -22, 0, 0]

  RANDOM_CAMERA  = [
    [ 20, -8,  2, 10, 0, 0],
    [-20,  8, -2, 10, 0, 0],
    [  0,  0,  3, 16, 0, 0],
    [ 12, -5, -1,  6, 0, 0],
    [-12,  5,  1,  6, 0, 0],
  ]

  SENDOUT_CAMERA = true
  RECALL_CAMERA  = true
  IDLE_CAMERA    = true
  MENU_CAMERA    = true
  ATTACK_CAMERA  = true
  FAINT_CAMERA   = true
  STATUS_CAMERA  = true
  LOCK_PLAYER_SPRITE = true
  GLUE_POKEMON_TO_SHADOW = true
  RESYNC_ON_POKEMON_CHANGE = true

  #-----------------------------------------------------------------------------
  # Shake de cámara e impacto dinámico
  #-----------------------------------------------------------------------------
  CRIT_SHAKE_CAMERA = true
  CRIT_SHAKE_AMP    = 6.0    # amplitud inicial del shake, en píxeles
  CRIT_SHAKE_DECAY  = 0.80   # qué tan rápido se apaga (más cerca de 1 = dura más)

  FAINT_SHAKE_CAMERA = true
  FAINT_SHAKE_AMP    = 4.0
  FAINT_SHAKE_DECAY  = 0.82

  SHAKE_RETARGET_HZ = 14.0
  SHAKE_SMOOTHING   = 0.5

  DYNAMIC_ZOOM_CAMERA        = true
  CRIT_ZOOM_PUNCH            = 14
  SUPER_EFFECTIVE_ZOOM_PUNCH = 8

  IDLE_USE_EASED      = false
  IDLE_EASED_DURATION = 50

  #-----------------------------------------------------------------------------
  # Auto-stretch del battleback
  #-----------------------------------------------------------------------------

  STRETCH_BACKGROUNDS = true

  # Paneo máximo
  MAX_PAN_X = 80
  MAX_PAN_Y = 20

  PAN_SAFETY_MARGIN = 24 
  MAX_ZOOM          = 1.25 
  MIN_VALID_BG_SIZE = 8

  BG_ZOOM_OVERRIDE = nil

  DBK_ANIMATED = nil

  PAN_PRIORITY = {
    idle:    1,
    home:    2,
    menu:    3,
    faint:   4,
    sendout: 5,
    recall:  5,
    attack:  6,
    status:  6,
    forced:  10
  }

  def self.screen_width
    return Settings::SCREEN_WIDTH if defined?(Settings) && Settings.const_defined?(:SCREEN_WIDTH)
    Graphics.width
  end

  def self.screen_height
    return Settings::SCREEN_HEIGHT if defined?(Settings) && Settings.const_defined?(:SCREEN_HEIGHT)
    Graphics.height
  end
end