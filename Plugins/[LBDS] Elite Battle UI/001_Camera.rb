#===============================================================================
# Dynamic Battle Camera
#===============================================================================
class EBSVector
  attr_reader   :x, :y, :angle, :scale, :x2, :y2, :shake_x, :shake_y
  attr_accessor :zoom1, :zoom2, :inc

  def initialize(x=0, y=0, angle=0, scale=1, zoom1=1, zoom2=1)
    @x=x.to_f; @y=y.to_f; @angle=angle.to_f
    @scale=scale.to_f; @zoom1=zoom1.to_f; @zoom2=zoom2.to_f
    @inc    = 0.2
    @set    = [@x,@y,@angle,@scale,@zoom1,@zoom2]
    @locked = false
    @duration = nil
    @elapsed  = 0.0
    @start    = @set.dup
    @last_tick = Time.now
    @shake_amp            = 0.0
    @shake_decay          = 0.8
    @shake_x              = 0.0
    @shake_y              = 0.0
    @shake_target_x       = 0.0
    @shake_target_y       = 0.0
    @shake_retarget_timer = 0.0
    @shake_retarget_hz    = 16.0
    @shake_smoothing      = 0.6
    self.calculate
  end

  def calculate
    rad = @angle*(Math::PI/180)
    @x2 = @x + Math.cos(rad)*@scale
    @y2 = @y - Math.sin(rad)*@scale
  end

  def set(*args)
    v = args[0].is_a?(Array) ? args[0] : args
    @set = v.map { |n| n.to_f }
    @duration = nil 
  end

  def force_set(*args)
    v = args[0].is_a?(Array) ? args[0] : args
    @x,@y,@angle,@scale,@zoom1,@zoom2 = *v.map { |n| n.to_f }
    @set = [@x,@y,@angle,@scale,@zoom1,@zoom2]
    @duration = nil
    self.calculate
  end

  def set_eased(target, duration_frames)
    v = target.is_a?(Array) ? target : [target]
    @start    = [@x,@y,@angle,@scale,@zoom1,@zoom2]
    @set      = v.map { |n| n.to_f }
    @duration = [duration_frames.to_f, 1.0].max
    @elapsed  = 0.0
  end
  def self.ease_in_out_cubic(t)
    t = 0.0 if t < 0.0
    t = 1.0 if t > 1.0
    t < 0.5 ? 4*t*t*t : 1-((-2*t+2)**3)/2
  end

  def add(field, amount=0.0)
    idx = { "x"=>0,"y"=>1,"angle"=>2,"scale"=>3,"zoom1"=>4,"zoom2"=>5 }[field]
    return unless idx
    cur = [@x,@y,@angle,@scale,@zoom1,@zoom2][idx]
    @set[idx] = cur + amount
  end

  def setXY(x,y); @set[0]=x.to_f; @set[1]=y.to_f; end
  def lock;   @locked = !@locked; end
  def locked?; return @locked; end
  def update
    now = Time.now
    dt  = now - @last_tick
    @last_tick = now
    dt = 1.0/60.0 if dt <= 0.0 || dt > 0.25

    ebs_update_shake(dt)

    if @duration
      @elapsed += dt * 60.0
      t = @elapsed / @duration
      p = EBSVector.ease_in_out_cubic(t)
      @x     = @start[0] + (@set[0]-@start[0])*p
      @y     = @start[1] + (@set[1]-@start[1])*p
      @angle = @start[2] + (@set[2]-@start[2])*p
      @scale = @start[3] + (@set[3]-@start[3])*p
      @zoom1 = @start[4] + (@set[4]-@start[4])*p
      @zoom2 = @start[5] + (@set[5]-@start[5])*p
      @duration = nil if t >= 1.0
      self.calculate
      return
    end

    base = @inc.clamp(0.001, 0.999)
    k    = 1.0 - (1.0 - base)**(dt * 60.0)
    @x     += (@set[0]-@x)    *k
    @y     += (@set[1]-@y)    *k
    @angle += (@set[2]-@angle)*k
    @scale += (@set[3]-@scale)*k
    @zoom1 += (@set[4]-@zoom1)*k
    @zoom2 += (@set[5]-@zoom2)*k
    self.calculate
  end

  def finished?
    return false if @duration
    diffs = [@set[0]-@x, @set[1]-@y, @set[2]-@angle, @set[3]-@scale, @set[4]-@zoom1, @set[5]-@zoom2]
    diffs.all? { |d| (d*@inc).abs <= 0.05 }
  end

  #-----------------------------------------------------------------------------
  # shake – dispara una sacudida de cámara.
  #-----------------------------------------------------------------------------
  def shake(amplitude, decay=0.8, retarget_hz=16.0, smoothing=0.6)
    @shake_amp         = [@shake_amp, amplitude.to_f].max
    @shake_decay       = decay.to_f.clamp(0.5, 0.98)
    @shake_retarget_hz = retarget_hz.to_f.clamp(1.0, 60.0)
    @shake_smoothing   = smoothing.to_f.clamp(0.05, 0.95)
  end

  def ebs_update_shake(dt)
    if @shake_amp > 0.05
      safety = 0
      while @shake_retarget_timer <= 0.0 && safety < 30
        @shake_target_x = (rand - 0.5) * 2.0 * @shake_amp
        @shake_target_y = (rand - 0.5) * 2.0 * @shake_amp
        @shake_retarget_timer += (1.0 / @shake_retarget_hz)
        safety += 1
      end
      @shake_retarget_timer -= dt
      k = 1.0 - (1.0 - @shake_smoothing)**(dt * 60.0)
      @shake_x += (@shake_target_x - @shake_x) * k
      @shake_y += (@shake_target_y - @shake_y) * k
      falloff     = @shake_decay ** (dt * 60.0)
      @shake_amp *= falloff
    else
      @shake_amp            = 0.0
      @shake_x              = 0.0
      @shake_y              = 0.0
      @shake_target_x       = 0.0
      @shake_target_y       = 0.0
      @shake_retarget_timer = 0.0
    end
  end

  def spoof(*args)
    v = args[0].is_a?(Array) ? args[0] : args
    x,y,ang,sc = v[0].to_f,v[1].to_f,v[2].to_f,v[3].to_f
    rad = ang*(Math::PI/180)
    return x+Math.cos(rad)*sc, y-Math.sin(rad)*sc
  end
end

#===============================================================================
# Battle::Scene
#===============================================================================
class Battle::Scene
  attr_reader   :vector
  attr_accessor :orgPos
  class << self
    attr_accessor :ebs_active_instance
  end

  alias ebs_initialize initialize
  def initialize
    ebs_initialize
    ebs_init_state
  end

  alias ebs_pbInitSprites pbInitSprites
  def pbInitSprites
    ebs_pbInitSprites
    ebs_setup_vector
  end

  def ebs_init_state
    Battle::Scene.ebs_active_instance = self
    @vector        = nil
    @ebs_v1        = nil
    @ebs_idle      = 0
    @ebs_last_cam  = nil
    @orgPos        = nil
    @ebs_cam_dx    = 0
    @ebs_cam_dy    = 0
    @ebs_home      = {}
    @ebs_animating = false
    @ebs_verified  = false
    @ebs_bg_stretched = false
    @ebs_bg_bitmap_id = nil
    @ebs_bg_scale     = nil
    @ebs_pending_v    = nil
    @ebs_active_priority = 0
    @ebs_freeze_camera   = false
    @ebs_freeze_depth    = 0
    @ebs_dbk       = PluginManager.installed?("[DBK] Animated Pokémon System")
  end

  def ebs_setup_vector
    return unless EBSCamera::ENABLED
    px=PLAYER_BASE_X.to_f; py=PLAYER_BASE_Y.to_f
    fx=FOE_BASE_X.to_f;    fy=FOE_BASE_Y.to_f
    dx=fx-px; dy=py-fy
    angle = Math.atan2(dy,dx)*180.0/Math::PI
    scale = Math.sqrt(dx*dx+dy*dy)
    @ebs_v1 = [px,py,angle,scale,1.0,1.0]
    @vector  = EBSVector.new(*@ebs_v1)
    @vector.inc = EBSCamera::INC
    @ebs_cam_dx = 0
    @ebs_cam_dy = 0
    @ebs_home   = {}
    @ebs_bg_stretched = ebs_stretch_backgrounds
    ebs_save_home
  end
  def ebs_backgrounds_ready?
    return false unless @sprites
    spr = @sprites["battle_bg"]
    return false unless spr && spr.bitmap && !(spr.respond_to?(:disposed?) && spr.disposed?)
    return false if spr.bitmap.width < EBSCamera::MIN_VALID_BG_SIZE || spr.bitmap.height < EBSCamera::MIN_VALID_BG_SIZE
    return true
  end
  def ebs_bg_scale_factor(bitmap_w, bitmap_h)
    return EBSCamera::BG_ZOOM_OVERRIDE.to_f if EBSCamera::BG_ZOOM_OVERRIDE
    pan_x = EBSCamera::MAX_PAN_X + EBSCamera::PAN_SAFETY_MARGIN
    pan_y = EBSCamera::MAX_PAN_Y + EBSCamera::PAN_SAFETY_MARGIN
    scale_x_needed = (EBSCamera.screen_width  + 2*pan_x) / bitmap_w.to_f
    scale_y_needed = (EBSCamera.screen_height + 2*pan_y) / bitmap_h.to_f
    scale_x = [scale_x_needed, EBSCamera::MAX_ZOOM].min
    return [scale_x, scale_y_needed].max
  end

  def ebs_stretch_backgrounds
    return false unless EBSCamera::STRETCH_BACKGROUNDS && @sprites
    return false unless ebs_backgrounds_ready?
    spr = @sprites["battle_bg"]
    rect = spr.src_rect
    fw = (rect && rect.width  > 0) ? rect.width  : spr.bitmap.width
    fh = (rect && rect.height > 0) ? rect.height : spr.bitmap.height
    scale = [ebs_bg_scale_factor(fw, fh), 1.0].max
    if @ebs_home["battle_bg"]
      base_x, base_y = @ebs_home["battle_bg"]
    else
      base_x = (spr.x - @ebs_cam_dx) + (fw / 2.0 - spr.ox) * spr.zoom_x
      base_y = (spr.y - @ebs_cam_dy) + (fh / 2.0 - spr.oy) * spr.zoom_y
    end
    spr.ox = fw / 2
    spr.oy = fh / 2
    spr.zoom_x = scale
    spr.zoom_y = scale
    spr.x = (base_x + @ebs_cam_dx).round
    spr.y = (base_y + @ebs_cam_dy).round
    ebs_position_side_duplicates(spr, scale)
    @ebs_bg_bitmap_id = spr.bitmap.object_id
    @ebs_bg_scale     = scale
    return true
  end
  #-----------------------------------------------------------------------------
  def ebs_position_side_duplicates(bg, scale)
    return unless @sprites
    reach = bg.ox * bg.zoom_x
    bg_left_edge  = bg.x - reach
    bg_right_edge = bg.x + reach
    bg2 = @sprites["battle_bg2"]
    if !bg2 || (bg2.respond_to?(:disposed?) && bg2.disposed?)
      bg2         = Sprite.new(@viewport)
      bg2.mirror  = true
      @sprites["battle_bg2"] = bg2
    end
    if bg2.bitmap != bg.bitmap || (bg2.bitmap.respond_to?(:disposed?) && bg2.bitmap.disposed?)
      bg2.bitmap = bg.bitmap
    end
    bg2.z       = bg.z
    bg2.ox      = bg.ox * 2
    bg2.oy      = bg.oy
    bg2.zoom_x  = scale
    bg2.zoom_y  = scale
    bg2.x       = bg_left_edge.round
    bg2.y       = bg.y
    bg2.visible = true

    bg3 = @sprites["battle_bg3"]
    if !bg3 || (bg3.respond_to?(:disposed?) && bg3.disposed?)
      bg3         = Sprite.new(@viewport)
      bg3.mirror  = true
      @sprites["battle_bg3"] = bg3
    end
    if bg3.bitmap != bg.bitmap || (bg3.bitmap.respond_to?(:disposed?) && bg3.bitmap.disposed?)
      bg3.bitmap = bg.bitmap 
    end
    bg3.z       = bg.z
    bg3.ox      = 0
    bg3.oy      = bg.oy
    bg3.zoom_x  = scale
    bg3.zoom_y  = scale
    bg3.x       = bg_right_edge.round
    bg3.y       = bg.y
    bg3.visible = true
  end
  def ebs_backgrounds_stale?
    return false unless @sprites
    spr = @sprites["battle_bg"]
    return false unless spr && spr.bitmap && !(spr.respond_to?(:disposed?) && spr.disposed?)
    return true if @ebs_bg_bitmap_id.nil?
    return true if spr.bitmap.object_id != @ebs_bg_bitmap_id
    return true if @ebs_bg_scale.nil? || (spr.zoom_x - @ebs_bg_scale).abs > 0.01
    false
  end
  def ebs_resync_backgrounds
    return unless EBSCamera::ENABLED && @sprites
    @ebs_bg_stretched = ebs_stretch_backgrounds
    return unless @ebs_bg_stretched
    ["battle_bg", "battle_bg2", "battle_bg3"].each do |key|
      spr = @sprites[key]
      next unless spr && !(spr.respond_to?(:disposed?) && spr.disposed?)
      @ebs_home[key] = [spr.x - @ebs_cam_dx, spr.y - @ebs_cam_dy]
    end
  end
  def ebs_glue_pkmn_to_shadow
    return unless EBSCamera::GLUE_POKEMON_TO_SHADOW && @sprites && @ebs_home
    @sprites.each_key do |key|
      next unless key =~ /^pokemon_(\d+)$/
      idx = $1
      pkmn_spr = @sprites[key]
      sha_spr  = @sprites["shadow_#{idx}"]
      next unless pkmn_spr && sha_spr
      next if pkmn_spr.respond_to?(:disposed?) && pkmn_spr.disposed?
      next if sha_spr.respond_to?(:disposed?) && sha_spr.disposed?
      pkmn_home = @ebs_home[key]
      sha_home  = @ebs_home["shadow_#{idx}"]
      next unless pkmn_home && sha_home
      pkmn_spr.x = sha_spr.x + (pkmn_home[0] - sha_home[0])
      pkmn_spr.y = sha_spr.y + (pkmn_home[1] - sha_home[1])
    end
  end

  def ebs_battle_sprite?(key)
    return true if key.start_with?("battle_bg")
    return true if key == "base_0" || key == "base_1"
    return true if key =~ /^(player|trainer|pokemon)_\d/
    # Sombras: solo con el plugin DBK instalado
    if key =~ /^shadow_\d/
      return @ebs_dbk
    end
    return false
  end
  def ebs_locked_sprite?(key)
    return true if EBSCamera::LOCK_PLAYER_SPRITE && key =~ /^player_\d/
    return false
  end

  def ebs_dbk_shadow_ready?(spr)
    return spr.respond_to?(:iconBitmap) && !spr.iconBitmap.nil?
  end
  def ebs_save_home
    return unless @sprites
    @sprites.each do |key, spr|
      next unless spr && !(spr.respond_to?(:disposed?) && spr.disposed?)
      next unless ebs_battle_sprite?(key)
      # Sombra DBK sin bitmap todavía: no guardar posición incorrecta
      if key =~ /^shadow_\d/ && @ebs_dbk
        next unless ebs_dbk_shadow_ready?(spr)
      end
      @ebs_home[key] = [spr.x, spr.y]
    end
  end

  def self.ebs_apply_position_offset(spr, key)
    return unless defined?(EBSCamera) && EBSCamera::ENABLED && EBSCamera::RESYNC_ON_POKEMON_CHANGE
    scene = ebs_active_instance
    return unless scene

    home = [spr.x, spr.y]
    homes = scene.instance_variable_get(:@ebs_home)
    homes[key] = home if homes
    dx = scene.instance_variable_get(:@ebs_cam_dx) || 0
    dy = scene.instance_variable_get(:@ebs_cam_dy) || 0
    return if dx == 0 && dy == 0
    spr.x = home[0] + dx
    spr.y = home[1] + dy
  end

  def ebs_verify_home
    return unless @ebs_home && @sprites
    @sprites.each do |key, spr|
      next unless spr && !(spr.respond_to?(:disposed?) && spr.disposed?)
      next unless ebs_battle_sprite?(key)
      home = @ebs_home[key]
      next unless home
      if key =~ /^shadow_\d/ && @ebs_dbk
        next unless ebs_dbk_shadow_ready?(spr)
      end
      spr.x = home[0]
      spr.y = home[1]
    end
    ebs_glue_pkmn_to_shadow
    @ebs_cam_dx = 0
    @ebs_cam_dy = 0
  end

  def ebs_immediate_reset
    return unless @vector && @ebs_v1
    if EBSCamera::ENABLED
      ebs_reset_v(EBSCamera::INC_FAST, EBSCamera::PAN_PRIORITY[:forced])
      safety = 0
      until @vector.finished? || safety >= 120
        pbUpdate
        safety += 1
      end
    end
    @ebs_pending_v = nil
    @vector.force_set(@ebs_v1)
    ebs_verify_home
  end

  def ebs_capture_new_homes
    return unless @sprites
    @sprites.each do |key, spr|
      next unless spr && !(spr.respond_to?(:disposed?) && spr.disposed?)
      next unless ebs_battle_sprite?(key)
      next if @ebs_home[key]   # ya tiene home guardado, nada que hacer
      if key =~ /^shadow_\d/ && @ebs_dbk
        next unless ebs_dbk_shadow_ready?(spr)
      end
      home = [spr.x, spr.y]
      @ebs_home[key] = home
      if @ebs_cam_dx != 0 || @ebs_cam_dy != 0
        spr.x = home[0] + @ebs_cam_dx
        spr.y = home[1] + @ebs_cam_dy
      end
    end
  end

  #-----------------------------------------------------------------------------
  # alignBattleScene
  #-----------------------------------------------------------------------------
  def alignBattleScene
    return unless EBSCamera::ENABLED && @vector && @ebs_v1 && @sprites

    ncx = @vector.x - @ebs_v1[0] + @vector.shake_x
    ncy = @vector.y - @ebs_v1[1] + @vector.shake_y
    tx  = ncx.round
    ty  = ncy.round
    ddx = tx - @ebs_cam_dx
    ddy = ty - @ebs_cam_dy
    return if ddx == 0 && ddy == 0

    @sprites.each do |key, spr|
      next unless spr && !(spr.respond_to?(:disposed?) && spr.disposed?)
      next unless ebs_battle_sprite?(key)
      next if ebs_locked_sprite?(key)
      spr.x += ddx
      spr.y += ddy
    end

    @ebs_cam_dx += ddx
    @ebs_cam_dy += ddy
    ebs_glue_pkmn_to_shadow
  end

  #-----------------------------------------------------------------------------
  # animateBattleSprites
  #-----------------------------------------------------------------------------
  def animateBattleSprites
    return unless EBSCamera::ENABLED && @vector
    return if @ebs_freeze_camera
    if !@ebs_bg_stretched || ebs_backgrounds_stale?
      ebs_resync_backgrounds
    end
    in_speech = respond_to?(:pbInCinematicSpeech?) && pbInCinematicSpeech?

    if in_speech
      @ebs_pending_v = nil
      if !@vector.finished? || @ebs_active_priority != EBSCamera::PAN_PRIORITY[:forced]
        @vector.inc = EBSCamera::INC_FAST
        @vector.set(@ebs_v1)
        @ebs_active_priority = EBSCamera::PAN_PRIORITY[:forced]
      end
    elsif @ebs_pending_v && @vector.finished?
      pending = @ebs_pending_v
      @ebs_pending_v = nil
      if pending[:type] == :eased
        @vector.set_eased(pending[:target], pending[:duration])
      else
        @vector.inc = pending[:inc]
        @vector.set(pending[:target])
      end
      @ebs_active_priority = pending[:priority]
    end

    @ebs_idle = (@ebs_idle||0) + 1
    if !in_speech && EBSCamera::IDLE_CAMERA && @orgPos &&
       @ebs_idle > EBSCamera::IDLE_DELAY * Graphics.frame_rate &&
       @vector.finished?
      cams = EBSCamera::RANDOM_CAMERA
      if cams.length > 1
        loop do
          n = rand(cams.length)
          if n != @ebs_last_cam; @ebs_last_cam = n; break; end
        end
      elsif cams.length == 1
        @ebs_last_cam = 0
      else
        @ebs_last_cam = nil
      end
      if @ebs_last_cam
        if EBSCamera::IDLE_USE_EASED
          ebs_set_v_eased(cams[@ebs_last_cam], EBSCamera::IDLE_EASED_DURATION, EBSCamera::PAN_PRIORITY[:idle])
        else
          @vector.inc = 0.005 * (rand(4)+1)
          ebs_set_v(cams[@ebs_last_cam], EBSCamera::PAN_PRIORITY[:idle])
        end
      end
      @ebs_idle = (EBSCamera::IDLE_DELAY * Graphics.frame_rate * 0.5).to_i
    end
    @vector.update
    alignBattleScene
    at_home = !@ebs_animating && !@ebs_home.empty? &&
              @ebs_cam_dx == 0 && @ebs_cam_dy == 0
    if at_home
      unless @ebs_verified
        ebs_verify_home
        @ebs_verified = true
      end
    else
      @ebs_verified = false
    end
  end

  def moveEntireScene(x=0, y=0, update_graphics=false, update_input=false)
    return unless EBSCamera::ENABLED
    if @vector
      @vector.setXY(@vector.x+x, @vector.y+y)
      @vector.add("x",x); @vector.add("y",y)
    end
    if @sprites
      @sprites.each do |key, spr|
        next unless spr && !(spr.respond_to?(:disposed?) && spr.disposed?)
        next unless ebs_battle_sprite?(key)
        next if ebs_locked_sprite?(key)
        spr.x += x; spr.y += y
      end
    end
    @ebs_cam_dx += x; @ebs_cam_dy += y
    ebs_glue_pkmn_to_shadow
    @orgPos[0] += x if @orgPos
    pbGraphicsUpdate if update_graphics
    pbInputUpdate    if update_input
  end

  def ebs_request_vector(target, inc, priority = EBSCamera::PAN_PRIORITY[:home])
    return unless @vector
    current_priority = @ebs_active_priority || 0
    if @vector.finished? || priority >= current_priority
      @vector.inc = inc
      @vector.set(target)
      @ebs_active_priority = priority
      @ebs_pending_v = nil
    else
      @ebs_pending_v = { type: :exp, target: target, inc: inc, priority: priority }
    end
  end

  def ebs_set_v(delta, priority = EBSCamera::PAN_PRIORITY[:home])
    return unless @vector && @ebs_v1
    target = @ebs_v1.each_with_index.map { |v,i| v+(delta[i]||0) }
    ebs_request_vector(target, @vector.inc, priority)
  end

  def ebs_reset_v(inc=EBSCamera::INC, priority = EBSCamera::PAN_PRIORITY[:home])
    return unless @vector && @ebs_v1
    ebs_request_vector(@ebs_v1, inc, priority)
  end

  #-----------------------------------------------------------------------------
  #exclusivamente para los paneos de MENÚ.
  #-----------------------------------------------------------------------------
  def ebs_request_vector_eased(target, duration, priority = EBSCamera::PAN_PRIORITY[:menu])
    return unless @vector
    current_priority = @ebs_active_priority || 0
    if @vector.finished? || priority >= current_priority
      @vector.set_eased(target, duration)
      @ebs_active_priority = priority
      @ebs_pending_v = nil
    else
      @ebs_pending_v = { type: :eased, target: target, duration: duration, priority: priority }
    end
  end

  def ebs_set_v_eased(delta, duration, priority = EBSCamera::PAN_PRIORITY[:menu])
    return unless @vector && @ebs_v1
    target = @ebs_v1.each_with_index.map { |v,i| v+(delta[i]||0) }
    ebs_request_vector_eased(target, duration, priority)
  end

  def ebs_reset_v_eased(duration = EBSCamera::MENU_DURATION, priority = EBSCamera::PAN_PRIORITY[:menu])
    return unless @vector && @ebs_v1
    ebs_request_vector_eased(@ebs_v1, duration, priority)
  end

  def setVector(delta); ebs_set_v(delta); end

  def moveUpperRight(cw=nil)
    return unless EBSCamera::MENU_CAMERA && @vector
    ebs_set_v_eased(EBSCamera::UPPER_RIGHT, EBSCamera::MENU_DURATION, EBSCamera::PAN_PRIORITY[:menu])
    10.times do; cw.show if cw.respond_to?(:show); pbUpdate; end
  end

  def moveLowerLeft(cw=nil)
    return unless EBSCamera::MENU_CAMERA && @vector
    ebs_reset_v_eased(EBSCamera::MENU_DURATION, EBSCamera::PAN_PRIORITY[:menu])
    10.times do; cw.hide if cw.respond_to?(:hide); pbUpdate; end
  end

  def moveRight(cw=nil)
    return unless EBSCamera::MENU_CAMERA && @vector
    ebs_set_v_eased([80,0,0,0,0,0], EBSCamera::MENU_DURATION, EBSCamera::PAN_PRIORITY[:menu])
    10.times do; cw.show if cw.respond_to?(:show); pbUpdate; end
  end

  def moveLeft(cw=nil)
    return unless EBSCamera::MENU_CAMERA && @vector
    ebs_reset_v_eased(EBSCamera::MENU_DURATION, EBSCamera::PAN_PRIORITY[:menu])
    10.times do; cw.hide if cw.respond_to?(:hide); pbUpdate; end
  end

  def wait(frames=1, align=false)
    frames.times { animateBattleSprites; pbUpdate }
  end

  #===========================================================================
  # Hooks
  #===========================================================================
  alias ebs_pbFrameUpdate pbFrameUpdate
  def pbFrameUpdate(cw=nil)
    ebs_pbFrameUpdate(cw)
  end

  alias ebs_pbUpdate pbUpdate
  def pbUpdate(*args)
    animateBattleSprites
    ebs_pbUpdate(*args)
  end

  alias ebs_pbBattleIntroAnimation pbBattleIntroAnimation
  def pbBattleIntroAnimation
    @ebs_animating = true
    ebs_pbBattleIntroAnimation
    @ebs_animating = false
    ebs_save_home
  end

  alias ebs_pbSendOutBattlers pbSendOutBattlers
  def pbSendOutBattlers(sendOuts, startBattle=false)
    @ebs_animating = true
    ebs_immediate_reset
    ebs_pbSendOutBattlers(sendOuts, startBattle)
    @ebs_animating = false
    ebs_save_home
    return unless EBSCamera::SENDOUT_CAMERA && @vector && sendOuts.length > 0
    return if startBattle
    return if @battle.opposes?(sendOuts[0][0])
    @vector.inc = EBSCamera::INC_FAST
    ebs_set_v(EBSCamera::SENDOUTVECTOR2, EBSCamera::PAN_PRIORITY[:sendout])
  end

  alias ebs_pbRecall pbRecall
  def pbRecall(idxBattler)
    # Igual que en el sendout: el paneo de "cambio de Pokémon" es solo para
    # el jugador. Si el que retira es el rival, la cámara no se mueve.
    if EBSCamera::RECALL_CAMERA && @vector && idxBattler.even?
      @vector.inc = EBSCamera::INC_FAST
      ebs_set_v(EBSCamera::SENDOUTVECTOR2, EBSCamera::PAN_PRIORITY[:recall])
    end
    @ebs_animating = true
    ebs_pbRecall(idxBattler)
    @ebs_animating = false
    ebs_immediate_reset
  end

  alias ebs_pbFaintBattler pbFaintBattler
  def pbFaintBattler(battler)
    @ebs_animating = true
    ebs_pbFaintBattler(battler)
    @ebs_animating = false
    if EBSCamera::FAINT_CAMERA && @vector
      ebs_reset_v_eased(EBSCamera::FAINT_DURATION, EBSCamera::PAN_PRIORITY[:faint])
      ebs_shake(EBSCamera::FAINT_SHAKE_AMP, EBSCamera::FAINT_SHAKE_DECAY) if EBSCamera::FAINT_SHAKE_CAMERA
    end
  end

  alias ebs_pbBeginCommandPhase pbBeginCommandPhase
  def pbBeginCommandPhase
    if @vector
      ebs_reset_v_eased(EBSCamera::MENU_DURATION, EBSCamera::PAN_PRIORITY[:menu])
      @orgPos   = [@vector.x,@vector.y,@vector.angle,@vector.scale,
                   @vector.zoom1,@vector.zoom2]
      threshold_frames = EBSCamera::IDLE_DELAY * Graphics.frame_rate
      seed_frames       = threshold_frames - (EBSCamera::IDLE_DELAY_FIRST * Graphics.frame_rate)
      @ebs_idle = [seed_frames, 0].max.to_i
    end
    ebs_pbBeginCommandPhase
  end

  alias ebs_pbBeginAttackPhase pbBeginAttackPhase
  def pbBeginAttackPhase
    @ebs_idle = -1
    ebs_pbBeginAttackPhase
  end

  def ebs_wait_for_pan(max_frames=90)
    return unless @vector
    return if @ebs_freeze_camera
    safety = 0
    until @vector.finished? || safety >= max_frames
      pbUpdate
      safety += 1
    end
  end

  def ebs_push_freeze
    @ebs_freeze_depth  = (@ebs_freeze_depth || 0) + 1
    @ebs_freeze_camera = true
  end

  def ebs_pop_freeze
    @ebs_freeze_depth  = [(@ebs_freeze_depth || 1) - 1, 0].max
    @ebs_freeze_camera = false if @ebs_freeze_depth == 0
  end

  alias ebs_pbAnimation pbAnimation
  def pbAnimation(moveID, user, targets, hitNum=0)
    @ebs_animating = true
    if EBSCamera::ATTACK_CAMERA && @vector && user && user.respond_to?(:index)
      @vector.inc = EBSCamera::INC_FAST
      ebs_set_v(ebs_attack_vector_for(user, targets, moveID), EBSCamera::PAN_PRIORITY[:attack])
    end
    ebs_wait_for_pan
    ebs_push_freeze
    ebs_pbAnimation(moveID, user, targets, hitNum)
    ebs_pop_freeze
    ebs_impact_feedback(targets)
    @ebs_animating = false
  end

  def ebs_status_vector_for(user, target)
    focus = target || user
    return nil unless focus && focus.respond_to?(:index)
    focus.index.even? ? EBSCamera::PLAYERVECTOR : EBSCamera::ENEMYVECTOR
  end

  if method_defined?(:pbCommonAnimation)
    alias ebs_pbCommonAnimation pbCommonAnimation
    def pbCommonAnimation(name, user = nil, target = nil)
      @ebs_animating = true
      did_focus = false
      if EBSCamera::STATUS_CAMERA && @vector
        focus_vector = ebs_status_vector_for(user, target)
        if focus_vector
          @vector.inc = EBSCamera::INC_FAST
          ebs_set_v(focus_vector, EBSCamera::PAN_PRIORITY[:status])
          ebs_wait_for_pan
          ebs_push_freeze
          did_focus = true
        end
      end
      ebs_pbCommonAnimation(name, user, target)
      ebs_pop_freeze if did_focus
      @ebs_animating = false
    end
  else
    puts "[EBS] AVISO: no se encontró pbCommonAnimation en Battle::Scene — " +
           "las animaciones de estado/habilidad NO tendrán enfoque ni cámara " +
           "congelada. Si tu build usa otro nombre para este método, decímelo " +
           "para enganchar el hook correcto."
  end

  def ebs_attack_vector_for(user, targets, moveID = nil)
    list = targets.is_a?(Array) ? targets : (targets ? [targets] : [])
    list = list.select { |t| t && t.respond_to?(:index) }

    receiver_is_player_side = nil
    source = nil

    if !list.empty?
      all_player = list.all? { |t| t.index.even? }
      all_enemy  = list.all? { |t| !t.index.even? }
      if all_player
        receiver_is_player_side = true;  source = :resolved_targets
      elsif all_enemy
        receiver_is_player_side = false; source = :resolved_targets
      end
 
    end

    if receiver_is_player_side.nil?
      data = ebs_move_target_data(moveID)
      if data && (data.targets_foe || data.affects_foe_side)

        receiver_is_player_side = !user.index.even?
        source = :pbs_foe
      elsif data

        receiver_is_player_side = user.index.even?
        source = :pbs_self
      else

        receiver_is_player_side = !user.index.even?
        source = :fallback
      end
    end

    receiver_is_player_side ? EBSCamera::PLAYERVECTOR : EBSCamera::ENEMYVECTOR
  end

  def ebs_move_target_type(moveID)
    return nil unless moveID
    begin
      if defined?(GameData::Move)
        m = GameData::Move.respond_to?(:try_get) ? GameData::Move.try_get(moveID) : GameData::Move.get(moveID)
        return m&.target
      end
    rescue StandardError
    end
    nil
  end


  def ebs_move_target_data(moveID)
    sym = ebs_move_target_type(moveID)
    return nil unless sym
    begin
      if defined?(GameData::Target)
        return GameData::Target.respond_to?(:try_get) ? GameData::Target.try_get(sym) : GameData::Target.get(sym)
      end
    rescue StandardError
    end
    nil
  end

  def ebs_impact_feedback(targets)
    return unless @vector && EBSCamera::ENABLED
    return unless targets
    list = targets.is_a?(Array) ? targets : [targets]
    crit = false
    list.each do |t|
      next unless t && t.respond_to?(:damageState) && t.damageState
      ds = t.damageState
      crit = true if ds.respond_to?(:critical) && ds.critical
    end
    ebs_shake(EBSCamera::CRIT_SHAKE_AMP, EBSCamera::CRIT_SHAKE_DECAY) if crit && EBSCamera::CRIT_SHAKE_CAMERA
  end

  def ebs_shake(amplitude, decay=0.8)
    return unless @vector
    @vector.shake(amplitude, decay, EBSCamera::SHAKE_RETARGET_HZ, EBSCamera::SHAKE_SMOOTHING)
  end

  alias ebs_pbEndBattle pbEndBattle
  def pbEndBattle(result)
    ebs_pbEndBattle(result)
    @vector = nil
    Battle::Scene.ebs_active_instance = nil if Battle::Scene.ebs_active_instance.equal?(self)
  end
end

#===============================================================================
#nivel de sprite individual para el paneo de cámara.
#===============================================================================
class Battle::Scene::BattlerSprite < RPG::Sprite
  alias ebs_pbSetPosition pbSetPosition
  def pbSetPosition
    ebs_pbSetPosition
    return if !@_iconBitmap
    Battle::Scene.ebs_apply_position_offset(self, "pokemon_#{@index}")
  end
end

class Battle::Scene::BattlerShadowSprite < RPG::Sprite
  alias ebs_pbSetPosition pbSetPosition
  def pbSetPosition
    ebs_pbSetPosition
    return if !@_iconBitmap
    Battle::Scene.ebs_apply_position_offset(self, "shadow_#{@index}")
  end
end