
#===============================================================================
class Battle::Scene::TargetMenu
  alias_method :ebs_nextgen_vanilla_initialize, :initialize

  def initialize(viewport, z, sideSizes)
    ebs_nextgen_vanilla_initialize(viewport, z, sideSizes)
    return if !@buttonBitmap
    nextgen_path = EliteBattleUI::GRAPHICS_PATH + "cursor_target"
    return if !pbResolveBitmap(nextgen_path)
    @buttonBitmap.dispose
    @buttonBitmap = AnimatedBitmap.new(nextgen_path)
    @buttons&.each { |b| b.bitmap = @buttonBitmap.bitmap if b && !b.disposed? }
  end
end

#===============================================================================
# Fila de Pokéball al iniciar combate
#===============================================================================
class Battle::Scene::Animation::LineupAppear
  alias_method :ebs_nextgen_vanilla_createBall, :createBall

  def createBall(idxBall, delay, dir)
    idxParty = getPartyIndexFromBallIndex(idxBall)
    graphicFilename = "Graphics/UI/Battle/icon_ball_empty"
    if idxParty >= 0 && idxParty < @party.length && @party[idxParty]
      if !@party[idxParty].able?
        graphicFilename = "Graphics/UI/Battle/icon_ball_faint"
      elsif @party[idxParty].status != :NONE
        graphicFilename = "Graphics/UI/Battle/icon_ball_status"
      else
        graphicFilename = "Graphics/UI/Battle/icon_ball"
      end
    end
    graphicFilename = EliteBattleUI.resolve_graphic(graphicFilename)
    ball = addSprite(@sprites["partyBall_#{@side}_#{idxBall}"])
    ball.setVisible(delay, true)
    ball.setName(delay, graphicFilename)
    ball.setDelta(delay, dir * Graphics.width / 2, 0)
    ball.moveDelta(delay, 8, -dir * Graphics.width / 2, 0)
  end
end
