#===============================================================================
# Sistema de Puentes Curvos y Rampas (Slopes and Bridges)
# Opción B: Cámara Dinámica en Rampas, Movimiento Diagonal y Alineación de Eventos
#===============================================================================

#-------------------------------------------------------------------------------
# Extensiones en Game_Map para detección de tiles y pasabilidad
#-------------------------------------------------------------------------------
class Game_Map
  # Devuelve el ID numérico del Terrain Tag de puente o rampa en (x, y)
  def slope_bridge_tag(x, y)
    return 0 if !valid?(x, y)

    # 1. Capas extendidas de Maker Studio (si están activas)
    if defined?(MakerStudio) && MakerStudio.respond_to?(:each_extended_tile_at)
      MakerStudio.each_extended_tile_at(x, y) do |tile_id, tile_data|
        tag_id = tile_data["terrain_tag"] ? tile_data["terrain_tag"].to_i : 0
        if tag_id == 0 && tile_data["tileset_id"]
          ts = $data_tilesets[tile_data["tileset_id"].to_i]
          tag_id = ts ? (ts.terrain_tags[tile_id] || 0) : 0
        elsif tag_id == 0
          tag_id = @terrain_tags ? (@terrain_tags[tile_id] || 0) : 0
        end
        return tag_id if tag_id != 0 && SlopesAndBridgesConfig.all_tags.include?(tag_id)
      end
    end

    # 2. Capas nativas de RPG Maker (capas 2, 1, 0)
    [2, 1, 0].each do |layer|
      tile_id = data[x, y, layer]
      next if tile_id.nil? || tile_id == 0
      tag_id = @terrain_tags ? @terrain_tags[tile_id] : 0
      return tag_id if tag_id && tag_id != 0 && SlopesAndBridgesConfig.all_tags.include?(tag_id)
    end

    return 0
  end

  # Devuelve el desplazamiento visual en píxeles para el sprite en el tile (x, y)
  def slope_bridge_offset(x, y)
    tag = slope_bridge_tag(x, y)
    return 0 if tag == 0
    return SlopesAndBridgesConfig.sprite_offset_for(tag)
  end

  def slope_bridge_tile?(x, y)
    return slope_bridge_tag(x, y) != 0
  end

  def ramp_tile?(x, y)
    tag = slope_bridge_tag(x, y)
    return false if tag == 0
    return (SlopesAndBridgesConfig::TAG_MODES[tag] || :ramp) == :ramp
  end

  def diagonal_left?(x, y)
    return SlopesAndBridgesConfig::DIAGONAL_LEFT_TAGS.include?(slope_bridge_tag(x, y))
  end

  def diagonal_right?(x, y)
    return SlopesAndBridgesConfig::DIAGONAL_RIGHT_TAGS.include?(slope_bridge_tag(x, y))
  end

  # Alias para compatibilidad hacia atrás
  alias curved_bridge_offset slope_bridge_offset unless method_defined?(:curved_bridge_offset)
  alias curved_bridge_tile? slope_bridge_tile? unless method_defined?(:curved_bridge_tile?)

  # Garantizar pasabilidad a pie sobre puentes y rampas
  alias slope_bridge_playerPassable? playerPassable? unless method_defined?(:slope_bridge_playerPassable?)
  def playerPassable?(x, y, dir, self_event = nil)
    ret = slope_bridge_playerPassable?(x, y, dir, self_event)
    return ret if ret
    return true if SlopesAndBridgesConfig::ENSURE_PASSABLE && slope_bridge_tile?(x, y)
    return false
  end

  alias slope_bridge_passable? passable? unless method_defined?(:slope_bridge_passable?)
  def passable?(x, y, dir, self_event = nil)
    ret = slope_bridge_passable?(x, y, dir, self_event)
    return ret if ret
    return true if SlopesAndBridgesConfig::ENSURE_PASSABLE && slope_bridge_tile?(x, y)
    return false
  end
end

#-------------------------------------------------------------------------------
# Extensiones en Game_Character para offsets visuales del sprite
#-------------------------------------------------------------------------------
class Game_Character
  attr_accessor :slopes_and_bridges_offset_y

  def slopes_and_bridges_offset_y
    if @slopes_and_bridges_offset_y.nil?
      reset_slopes_and_bridges_offset
    end
    return @slopes_and_bridges_offset_y
  end

  alias curved_bridge_offset_y slopes_and_bridges_offset_y
  def curved_bridge_offset_y=(val)
    @slopes_and_bridges_offset_y = val
  end

  # Sincroniza el offset del sprite
  def reset_slopes_and_bridges_offset(target_x = nil, target_y = nil)
    target_x ||= @x
    target_y ||= @y
    if self.map
      @slopes_and_bridges_offset_y = self.map.slope_bridge_offset(target_x, target_y).to_f
    else
      @slopes_and_bridges_offset_y = 0.0
    end
  end
  alias reset_curved_bridge_offset reset_slopes_and_bridges_offset

  # Combina el offset visual con cualquier offset existente de Game_Character
  alias slope_bridge_y_offset y_offset unless method_defined?(:slope_bridge_y_offset)
  def y_offset
    base_offset = slope_bridge_y_offset
    return base_offset + slopes_and_bridges_offset_y.round
  end
  alias curved_bridge_y_offset slope_bridge_y_offset

  # Reseteo seguro de coordenadas con soporte de argumentos variables (*args)
  alias slope_bridge_moveto moveto unless method_defined?(:slope_bridge_moveto)
  def moveto(x, y, *args)
    slope_bridge_moveto(x, y, *args)
    reset_slopes_and_bridges_offset(x, y)
  end
  alias curved_bridge_moveto slope_bridge_moveto

  # Permitir corte diagonal en tiles de rampa diagonal (evita colisión con esquinas)
  alias slope_bridge_can_move_from_coordinate? can_move_from_coordinate? unless method_defined?(:slope_bridge_can_move_from_coordinate?)
  def can_move_from_coordinate?(start_x, start_y, dir, strict = false)
    if [1, 3, 7, 9].include?(dir)
      if self.map && (self.map.diagonal_left?(start_x, start_y) || self.map.diagonal_right?(start_x, start_y))
        dx = (dir == 9 || dir == 3) ? 1 : -1
        dy = (dir == 1 || dir == 3) ? 1 : -1
        dest_x = start_x + dx
        dest_y = start_y + dy
        return true if self.map.valid?(dest_x, dest_y)
      end
    end
    return slope_bridge_can_move_from_coordinate?(start_x, start_y, dir, strict)
  end

  # Actualización por frame del offset del sprite
  alias slope_bridge_update update unless method_defined?(:slope_bridge_update)
  def update
    slope_bridge_update
    update_slopes_and_bridges_sprite_offset
  end
  alias curved_bridge_update slope_bridge_update

  private

  # Interpolación suave del offset del sprite
  def update_slopes_and_bridges_sprite_offset
    @slopes_and_bridges_offset_y ||= 0.0
    return if !self.map

    if moving? && @move_time && @move_time > 0 && @move_timer
      raw_t = [[@move_timer.to_f / @move_time, 0.0].max, 1.0].min

      from_x = @move_initial_x || @x
      from_y = @move_initial_y || @y
      to_x   = @x
      to_y   = @y

      on_ramp = self.map.ramp_tile?(from_x, from_y) || self.map.ramp_tile?(to_x, to_y)
      mode = if on_ramp && defined?(SlopesAndBridgesConfig::RAMP_INTERPOLATION_MODE)
               SlopesAndBridgesConfig::RAMP_INTERPOLATION_MODE
             else
               SlopesAndBridgesConfig::INTERPOLATION_MODE
             end
      t = (mode == :smooth) ? (1.0 - Math.cos(raw_t * Math::PI)) / 2.0 : raw_t

      from_off = self.map.slope_bridge_offset(from_x, from_y).to_f
      to_off   = self.map.slope_bridge_offset(to_x, to_y).to_f

      @slopes_and_bridges_offset_y = from_off + (to_off - from_off) * t

      bob = defined?(SlopesAndBridgesConfig::RAMP_STEP_BOB) ? SlopesAndBridgesConfig::RAMP_STEP_BOB.to_f : 0.0
      if bob != 0 && from_x == to_x && from_y != to_y
        vertical_ramp = [[from_x, from_y], [to_x, to_y]].any? do |tx, ty|
          self.map.ramp_tile?(tx, ty) && !self.map.diagonal_left?(tx, ty) && !self.map.diagonal_right?(tx, ty)
        end
        @slopes_and_bridges_offset_y -= bob * Math.sin(raw_t * Math::PI) if vertical_ramp
      end

    elsif jumping? && @jump_time && @jump_time > 0 && @jump_timer
      raw_t = [[@jump_fraction || 0.0, 0.0].max, 1.0].min
      from_off = self.map.slope_bridge_offset(@jump_initial_x || @x, @jump_initial_y || @y).to_f
      to_off   = self.map.slope_bridge_offset(@x, @y).to_f
      @slopes_and_bridges_offset_y = from_off + (to_off - from_off) * raw_t

    else
      # Inmóvil:
      target_y = self.map.slope_bridge_offset(@x, @y).to_f
      diff = target_y - @slopes_and_bridges_offset_y
      if diff.abs > 0.01
        step = (@delta_t || (1.0 / Graphics.frame_rate)) * SlopesAndBridgesConfig::RESTING_DAMPING_SPEED
        if diff > 0
          @slopes_and_bridges_offset_y = [@slopes_and_bridges_offset_y + step, target_y].min
        else
          @slopes_and_bridges_offset_y = [@slopes_and_bridges_offset_y - step, target_y].max
        end
      else
        @slopes_and_bridges_offset_y = target_y
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Movimiento Diagonal en Game_Player
#-------------------------------------------------------------------------------
class Game_Player
  # Movimiento diagonal en rampas diagonales
  alias slope_bridge_move_generic move_generic unless method_defined?(:slope_bridge_move_generic)

  def move_generic(dir, turn_enabled = true)
    curr_x = @x
    curr_y = @y

    if self.map && self.map.diagonal_left?(curr_x, curr_y)
      if dir == 4 || dir == 8
        move_upper_left
        return
      elsif dir == 6 || dir == 2
        move_lower_right
        return
      end
    elsif self.map && self.map.diagonal_right?(curr_x, curr_y)
      if dir == 6 || dir == 8
        move_upper_right
        return
      elsif dir == 4 || dir == 2
        move_lower_left
        return
      end
    else
      # Entrada diagonal desde el suelo adyacente
      case dir
      when 4
        if self.map && self.map.diagonal_left?(curr_x - 1, curr_y - 1)
          move_upper_left
          return
        end
      when 6
        if self.map && self.map.diagonal_right?(curr_x + 1, curr_y - 1)
          move_upper_right
          return
        end
      end
    end

    slope_bridge_move_generic(dir, turn_enabled)
  end
end

#-------------------------------------------------------------------------------
# Hooks globales para sincronización de mapa y carga de partida
#-------------------------------------------------------------------------------
if defined?(EventHandlers)
  EventHandlers.add(:on_enter_map, :slopes_bridges_enter_map, proc {
    $game_player&.reset_slopes_and_bridges_offset
    $game_map&.events&.each_value { |e| e.reset_slopes_and_bridges_offset }
    if $game_temp&.respond_to?(:followers) && $game_temp.followers
      $game_temp.followers.each_follower { |event, _follower| event&.reset_slopes_and_bridges_offset }
    end
  })

  EventHandlers.add(:on_game_load, :slopes_bridges_game_load, proc {
    $game_player&.reset_slopes_and_bridges_offset
    $game_map&.events&.each_value { |e| e.reset_slopes_and_bridges_offset }
    if $game_temp&.respond_to?(:followers) && $game_temp.followers
      $game_temp.followers.each_follower { |event, _follower| event&.reset_slopes_and_bridges_offset }
    end
  })
end

