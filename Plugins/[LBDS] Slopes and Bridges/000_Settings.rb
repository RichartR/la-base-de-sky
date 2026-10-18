#===============================================================================
# Sistema de Puentes Curvos y Rampas (Slopes and Bridges)
# Configuración y Registro Automático de Terrain Tags
#===============================================================================
module SlopesAndBridgesConfig
  # 1. Modo de funcionamiento de cada Terrain Tag:
  # - :bridge -> Puente Curvo: Arco visual completo de sprite (sube y baja al mismo plano).
  # - :ramp   -> Rampa/Escalera: Utiliza efecto dinámico de cámara (Opción B).
  #              El personaje sube con un sutil paso escalonado y la cámara asciende
  #              mostrando la montaña. Al llegar a la cima queda a offset 0px exacto,
  #              alineado con todos los eventos y árboles del piso superior.
  TAG_MODES = {
    # --- PUENTES CURVOS (Arco de sprite completo) ---
    18 => :bridge, # Puente Curvo (-12px)
    19 => :bridge, # Puente Curvo (-24px)
    20 => :bridge, # Puente Curvo (-32px)

    # --- RAMPAS VERTICALES (Cámara dinámica) ---
    21 => :ramp,   # Rampa Vert (Peldaño 1)
    22 => :ramp,   # Rampa Vert (Peldaño 2)
    23 => :ramp,   # Rampa Vert (Peldaño de coronación)

    # --- RAMPAS DIAGONALES ---
    24 => :ramp,   # Rampa Diag Izq
    25 => :ramp    # Rampa Diag Der
  }

  # 2. Desplazamiento visual para PUENTES CURVOS (en píxeles):
  BRIDGE_SPRITE_OFFSETS = {
    18 => -12,
    19 => -24,
    20 => -32
  }

  # 3. Inclinación y relieve del sprite en peldaños de rampa (en píxeles):
  # Permite sentir el relieve de cada peldaño de forma fluida
  # para que el paso a la meseta superior sea 100% continuo y sin saltos ni desalineación.
  RAMP_SPRITE_OFFSETS = {
    21 => -4,   # Peldaño 1 (-4 px)
    22 => -8,   # Peldaño 2 (-8 px)
    23 => -12,   # Peldaño 3 / Cima (-6 px)
    24 => -6,   # Rampa diagonal izquierda (-6 px)
    25 => -6    # Rampa diagonal derecha (-6 px)
  }

  # 4. Rampas Diagonales:
  # - DIAGONAL_LEFT_TAGS: Sube hacia arriba-izquierda (o baja hacia abajo-derecha).
  # - DIAGONAL_RIGHT_TAGS: Sube hacia arriba-derecha (o baja hacia abajo-izquierda).
  DIAGONAL_LEFT_TAGS  = [24]
  DIAGONAL_RIGHT_TAGS = [25]

  # 5. Modo de interpolación durante el paso del personaje:
  INTERPOLATION_MODE = :smooth

  # 6. Garantizar pasabilidad a pie sobre puentes y rampas
  ENSURE_PASSABLE = true

  # Velocidad de amortiguación (en px/s) al detenerse
  RESTING_DAMPING_SPEED = 25.0

  # Helper para obtener el offset visual de sprite según el modo del tag
  def self.sprite_offset_for(tag_num)
    mode = TAG_MODES[tag_num] || :ramp
    if mode == :bridge
      return BRIDGE_SPRITE_OFFSETS[tag_num] || -16
    else
      return RAMP_SPRITE_OFFSETS[tag_num] || -6
    end
  end

  # Helper de todos los tags activos
  def self.all_tags
    return (TAG_MODES.keys | DIAGONAL_LEFT_TAGS | DIAGONAL_RIGHT_TAGS).sort
  end
end

# Alias de compatibilidad hacia atrás
CurvedBridgeConfig = SlopesAndBridgesConfig unless defined?(CurvedBridgeConfig)

#===============================================================================
# Registro automático en el motor del juego (GameData::TerrainTag)
#===============================================================================
if defined?(GameData::TerrainTag)
  # Tags diagonales con identificadores estándar
  SlopesAndBridgesConfig::DIAGONAL_LEFT_TAGS.each do |tag_num|
    GameData::TerrainTag.register({
      :id        => :StairLeft,
      :id_number => tag_num,
      :real_name => "Rampa Diag Izq",
      :bridge    => false
    })
  end

  SlopesAndBridgesConfig::DIAGONAL_RIGHT_TAGS.each do |tag_num|
    GameData::TerrainTag.register({
      :id        => :StairRight,
      :id_number => tag_num,
      :real_name => "Rampa Diag Der",
      :bridge    => false
    })
  end

  # Puentes curvos
  SlopesAndBridgesConfig::BRIDGE_SPRITE_OFFSETS.each do |tag_num, off|
    tag_sym = "BridgeCurve_#{tag_num}".to_sym
    px_str = (off > 0) ? "+#{off}px" : "#{off}px"
    GameData::TerrainTag.register({
      :id        => tag_sym,
      :id_number => tag_num,
      :real_name => "Puente Curvo (#{px_str})",
      :bridge    => false
    })
  end

  # Rampas verticales
  SlopesAndBridgesConfig::RAMP_SPRITE_OFFSETS.each do |tag_num, _off|
    next if SlopesAndBridgesConfig::DIAGONAL_LEFT_TAGS.include?(tag_num)
    next if SlopesAndBridgesConfig::DIAGONAL_RIGHT_TAGS.include?(tag_num)
    tag_sym = "Ramp_#{tag_num}".to_sym
    GameData::TerrainTag.register({
      :id        => tag_sym,
      :id_number => tag_num,
      :real_name => "Rampa Vert (Tag #{tag_num})",
      :bridge    => false
    })
  end
end
