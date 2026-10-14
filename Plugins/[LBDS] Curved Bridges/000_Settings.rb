#===============================================================================
# Sistema de Puentes Curvos Visuales (Curved Bridges)
# Configuración y Registro Automático de Terrain Tags
#===============================================================================
module CurvedBridgeConfig
  # Mapeo de Terrain Tags a desplazamiento visual en el eje Y (en píxeles).
  # - Clave: ID numérico del Terrain Tag asignado al tile (ej: 18, 19, 20, 21...).
  # - Valor: Píxeles de desplazamiento (negativo = sube, 0 = plano, positivo = baja).
  TAG_OFFSETS = {
    18 => 0,    # Sección 0 / Base (0 px)
    19 => -12,  # Sección 1 / Subida leve (-12 px)
    20 => -24,  # Sección 2 / Subida media (-24 px)
    21 => -32   # Sección 3 / Cúspide del puente (-32 px)
  }

  # Modo de interpolación durante el paso del personaje:
  # :smooth -> Curva suave cosenoidal (sin saltos bruscos)
  # :linear -> Progresión lineal continua
  INTERPOLATION_MODE = :smooth

  # Garantiza que el jugador siempre pueda cruzar el puente a pie
  ENSURE_BRIDGE_PASSABLE = true

  # Velocidad de amortiguación (en px/s) si el personaje aparece quieto en un tile
  RESTING_DAMPING_SPEED = 20.0
end

#===============================================================================
# 1. Registro automático en el motor del juego (GameData::TerrainTag)
# Se genera automáticamente a partir de los números de TAG_OFFSETS.
#===============================================================================
if defined?(GameData::TerrainTag)
  CurvedBridgeConfig::TAG_OFFSETS.each do |tag_num, off|
    tag_sym = "BridgeCurve_#{tag_num}".to_sym
    px_str = (off > 0) ? "+#{off}px" : "#{off}px"
    GameData::TerrainTag.register({
      :id        => tag_sym,
      :id_number => tag_num,
      :real_name => "Puente Curvo (#{px_str})",
      :bridge    => false
    })
  end
end

