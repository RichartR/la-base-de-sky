#===============================================================================
# Parches varios de compatibilidad para Battle::Scene y DBK
#===============================================================================
class Battle::Scene::Animation
  alias ebs_darkenBattlefield darkenBattlefield
  def darkenBattlefield(battle, delay = 0, idxBattler = -1, sound = nil)
    ebs_darkenBattlefield(battle, delay, idxBattler, sound)
    ebs_preserve_battle_bg(delay)
  end

  alias ebs_revertBattlefield revertBattlefield
  def revertBattlefield(battle, delay)
    ebs_revertBattlefield(battle, delay)
    ebs_preserve_battle_bg(delay)
  end

  def ebs_preserve_battle_bg(delay)
    return unless defined?(EBSCamera) && EBSCamera::ENABLED
    return unless @sprites
    bg = @sprites["battle_bg"]
    return unless bg && bg.bitmap && !(bg.respond_to?(:disposed?) && bg.disposed?)
    fix = addSprite(bg, PictureOrigin::CENTER)
    fix.setXY(delay, bg.x, bg.y)
    fix.setZoomXY(delay, bg.zoom_x, bg.zoom_y)
  end
end

#===============================================================================
# Quitar fondo del command bar
# por tipo de terreno
#===============================================================================
class Battle::Scene
  alias_method :ebs_nextgen_vanilla_pbCreateBackdropSprites, :pbCreateBackdropSprites

  def pbCreateBackdropSprites
    case @battle.time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    # Fondo de batalla y bases: exactamente igual que vanilla.
    backdropFilename = @battle.backdrop
    baseFilename = @battle.backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @battle.backdropBase) if @battle.backdropBase
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      backdropFilename = trialName if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_bg", trialName))
      trialName = sprintf("%s_%s", baseFilename, time)
      baseFilename = trialName if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", trialName))
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", baseFilename)) && @battle.backdropBase
      baseFilename = @battle.backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        baseFilename = trialName if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", trialName))
      end
    end
    battleBG   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    playerBase = "Graphics/Battlebacks/" + baseFilename + "_base0"
    enemyBase  = "Graphics/Battlebacks/" + baseFilename + "_base1"
    bg = pbAddSprite("battle_bg", 0, 0, battleBG, @viewport)
    bg.z = 0
    if !Settings::DISABLE_SLIDING_BACKGROUND
      bg = pbAddSprite("battle_bg2", -Graphics.width, 0, battleBG, @viewport)
      bg.z      = 0
      bg.mirror = true
    end
    if Settings::SHOW_BATTLE_BASES
      2.times do |side|
        baseX, baseY = Battle::Scene.pbBattlerPosition(side)
        baseY += EliteBattleUI::BattleLayout::PLAYER_BASE_Y_OFFSET if side.zero?   # solo el jugador
        next if side.zero? && !pbResolveBitmap(playerBase)   # No existe el gráfico de base del jugador
        next if !side.zero? && !pbResolveBitmap(enemyBase)   # No existe el gráfico de base del rival
        base = pbAddSprite("base_#{side}", baseX, baseY, (side == 0) ? playerBase : enemyBase, @viewport)
        base.z = 3
        if base.bitmap
          base.ox = base.bitmap.width / 2
          base.oy = (side == 0) ? base.bitmap.height : base.bitmap.height / 2
        end
      end
    end
    cmdBarBG = pbAddSprite("cmdBar_bg", 0, Graphics.height - MESSAGE_BOX_HEIGHT, nil, @viewport)
    cmdBarBG.z = 180
  end
end

#===============================================================================
# Bajar el sprite trasero del jugador (el entrenador)
#===============================================================================
class Battle::Scene
  alias_method :ebs_nextgen_vanilla_pbCreateTrainerBackSprite, :pbCreateTrainerBackSprite

  def pbCreateTrainerBackSprite(idxTrainer, trainerType, numTrainers = 1)
    if idxTrainer == 0   # Sprite del jugador
      trainerFile = GameData::TrainerType.player_back_sprite_filename(trainerType)
    else   # Sprite del entrenador compañero
      trainerFile = GameData::TrainerType.back_sprite_filename(trainerType)
    end
    trainerFile = nil if !pbResolveBitmap(trainerFile)
    spriteX, spriteY = Battle::Scene.pbTrainerPosition(0, idxTrainer, numTrainers)
    spriteY += EliteBattleUI::BattleLayout::PLAYER_SPRITE_Y_OFFSET if idxTrainer == 0   # solo el jugador
    trainer = pbAddSprite("player_#{idxTrainer + 1}", spriteX, spriteY, trainerFile, @viewport)
    return if !trainer.bitmap
    trainer.z = 80 + idxTrainer
    if trainer.bitmap.width > trainer.bitmap.height * 2
      trainer.src_rect.x     = 0
      trainer.src_rect.width = trainer.bitmap.width / 5
    end
    trainer.ox = trainer.src_rect.width / 2
    trainer.oy = trainer.bitmap.height
  end
end