#===============================================================================
# Sistema de Puentes Curvos Visuales (Curved Bridges)
# Lógica Principal e Integración con el Motor
#===============================================================================

#-------------------------------------------------------------------------------
# Métodos auxiliares y de pasabilidad en Game_Map
#-------------------------------------------------------------------------------
class Game_Map
  # Devuelve el desplazamiento visual en píxeles configurado para el tile en (x, y).
  # Si no hay ningún tag de puente curvo asignado, retorna 0.
  def curved_bridge_offset(x, y)
    return 0 if !valid?(x, y)

    # 1. Capas extendidas de Maker Studio (si se usan)
    if defined?(MakerStudio) && MakerStudio.respond_to?(:each_extended_tile_at)
      MakerStudio.each_extended_tile_at(x, y) do |tile_id, tile_data|
        tag_id = tile_data["terrain_tag"] ? tile_data["terrain_tag"].to_i : 0
        if tag_id == 0 && tile_data["tileset_id"]
          ts = $data_tilesets[tile_data["tileset_id"].to_i]
          tag_id = ts ? (ts.terrain_tags[tile_id] || 0) : 0
        elsif tag_id == 0
          tag_id = @terrain_tags ? (@terrain_tags[tile_id] || 0) : 0
        end
        return CurvedBridgeConfig::TAG_OFFSETS[tag_id] if CurvedBridgeConfig::TAG_OFFSETS.key?(tag_id)
      end
    end

    # 2. Capas nativas de RPG Maker (capas 2, 1, 0)
    [2, 1, 0].each do |layer|
      tile_id = data[x, y, layer]
      next if tile_id.nil? || tile_id == 0
      tag_id = @terrain_tags ? @terrain_tags[tile_id] : 0
      return CurvedBridgeConfig::TAG_OFFSETS[tag_id] if CurvedBridgeConfig::TAG_OFFSETS.key?(tag_id)
    end

    return 0
  end

  # Comprueba si una casilla (x, y) tiene asignado alguno de los tags de puente curvo
  def curved_bridge_tile?(x, y)
    return false if !valid?(x, y)

    # Revisar en Maker Studio
    if defined?(MakerStudio) && MakerStudio.respond_to?(:each_extended_tile_at)
      MakerStudio.each_extended_tile_at(x, y) do |tile_id, tile_data|
        tag_id = tile_data["terrain_tag"] ? tile_data["terrain_tag"].to_i : 0
        if tag_id == 0 && tile_data["tileset_id"]
          ts = $data_tilesets[tile_data["tileset_id"].to_i]
          tag_id = ts ? (ts.terrain_tags[tile_id] || 0) : 0
        elsif tag_id == 0
          tag_id = @terrain_tags ? (@terrain_tags[tile_id] || 0) : 0
        end
        return true if tag_id != 0 && CurvedBridgeConfig::TAG_OFFSETS.key?(tag_id)
      end
    end

    # Revisar capas nativas
    [2, 1, 0].each do |layer|
      tile_id = data[x, y, layer]
      next if tile_id.nil? || tile_id == 0
      tag_id = @terrain_tags ? @terrain_tags[tile_id] : 0
      return true if tag_id && tag_id != 0 && CurvedBridgeConfig::TAG_OFFSETS.key?(tag_id)
    end

    return false
  end

  # Garantiza que el jugador siempre pueda transitar por los tiles del puente
  alias curved_bridge_playerPassable? playerPassable? unless method_defined?(:curved_bridge_playerPassable?)
  def playerPassable?(x, y, dir, self_event = nil)
    ret = curved_bridge_playerPassable?(x, y, dir, self_event)
    return ret if ret
    if CurvedBridgeConfig::ENSURE_BRIDGE_PASSABLE && curved_bridge_tile?(x, y)
      return true
    end
    return false
  end
end

#-------------------------------------------------------------------------------
# Extensiones en Game_Player para aplicar el desplazamiento visual
#-------------------------------------------------------------------------------
class Game_Player < Game_Character
  attr_accessor :curved_bridge_offset_y

  def curved_bridge_offset_y
    @curved_bridge_offset_y ||= 0.0
    return @curved_bridge_offset_y
  end

  # Sincroniza inmediatamente el offset visual con la casilla actual o dada
  def reset_curved_bridge_offset(target_x = nil, target_y = nil)
    target_x ||= @x
    target_y ||= @y
    if self.map
      @curved_bridge_offset_y = self.map.curved_bridge_offset(target_x, target_y).to_f
    else
      @curved_bridge_offset_y = 0.0
    end
  end

  # Combina el offset visual del puente con cualquier offset existente de Game_Character
  alias curved_bridge_y_offset y_offset unless method_defined?(:curved_bridge_y_offset)
  def y_offset
    base_offset = curved_bridge_y_offset
    return base_offset + curved_bridge_offset_y.round
  end

  # Reseteo al cambiar de mapa, teletransportar o reposicionar al jugador
  alias curved_bridge_moveto moveto unless method_defined?(:curved_bridge_moveto)
  def moveto(x, y, *args)
    curved_bridge_moveto(x, y, *args)
    reset_curved_bridge_offset(x, y)
  end

  # Actualización por frame del offset visual
  alias curved_bridge_update update unless method_defined?(:curved_bridge_update)
  def update
    curved_bridge_update
    update_curved_bridge_movement_offset
  end

  private

  # Calcula la transición suave del offset según el estado del jugador
  def update_curved_bridge_movement_offset
    @curved_bridge_offset_y ||= 0.0
    return if !self.map

    if moving? && @move_time && @move_time > 0 && @move_timer
      # Progreso del paso dentro de la casilla actual (0.0 a 1.0)
      raw_t = [[@move_timer.to_f / @move_time, 0.0].max, 1.0].min
      t = if CurvedBridgeConfig::INTERPOLATION_MODE == :smooth
            (1.0 - Math.cos(raw_t * Math::PI)) / 2.0
          else
            raw_t
          end

      start_y = self.map.curved_bridge_offset(@move_initial_x || @x, @move_initial_y || @y).to_f
      end_y   = self.map.curved_bridge_offset(@x, @y).to_f
      @curved_bridge_offset_y = start_y + (end_y - start_y) * t

    elsif jumping? && @jump_time && @jump_time > 0 && @jump_timer
      # Interpolación continua durante el arco del salto
      raw_t = [[@jump_fraction || 0.0, 0.0].max, 1.0].min
      start_y = self.map.curved_bridge_offset(@jump_initial_x || @x, @jump_initial_y || @y).to_f
      end_y   = self.map.curved_bridge_offset(@x, @y).to_f
      @curved_bridge_offset_y = start_y + (end_y - start_y) * raw_t

    else
      # Cuando está inmóvil, ajusta suavemente hacia la altura correspondiente a su casilla
      target_y = self.map.curved_bridge_offset(@x, @y).to_f
      diff = target_y - @curved_bridge_offset_y
      if diff.abs > 0.01
        step = (@delta_t || (1.0 / Graphics.frame_rate)) * CurvedBridgeConfig::RESTING_DAMPING_SPEED
        if diff > 0
          @curved_bridge_offset_y = [@curved_bridge_offset_y + step, target_y].min
        else
          @curved_bridge_offset_y = [@curved_bridge_offset_y - step, target_y].max
        end
      else
        @curved_bridge_offset_y = target_y
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Hooks en eventos globales para asegurar sincronización en cambios de mapa y carga
#-------------------------------------------------------------------------------
if defined?(EventHandlers)
  EventHandlers.add(:on_enter_map, :curved_bridges_enter_map, proc {
    $game_player&.reset_curved_bridge_offset
  })

  EventHandlers.add(:on_game_load, :curved_bridges_game_load, proc {
    $game_player&.reset_curved_bridge_offset
  })
end
