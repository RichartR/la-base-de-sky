
#===============================================================================
class Battle::Scene
  alias_method :ebs_nextgen_vanilla_pbInitSprites, :pbInitSprites
  alias_method :ebs_nextgen_vanilla_pbShowWindow,  :pbShowWindow

  MESSAGE_BASE_COLOR   = EliteBattleUI::MessageBox::BASE_COLOR
  MESSAGE_SHADOW_COLOR = EliteBattleUI::MessageBox::SHADOW_COLOR

  MESSAGE_BASE_CRITICAL_COLOR   = EliteBattleUI::MessageBox::CRITICAL_BASE_COLOR
  MESSAGE_SHADOW_CRITICAL_COLOR = EliteBattleUI::MessageBox::CRITICAL_SHADOW_COLOR

  def pbInitSprites
    ebs_nextgen_vanilla_pbInitSprites
    # 1) Fondo de la caja de mensaje
    if pbResolveBitmap(EliteBattleUI::MessageBox::GRAPHICS_PATH + "newBattleMessageBox")
      @sprites["messageBox"].setBitmap(EliteBattleUI::MessageBox::GRAPHICS_PATH + "newBattleMessageBox")
    end
    # 2) Colores del texto
    msg_window = @sprites["messageWindow"]
    if msg_window
      msg_window.baseColor   = EliteBattleUI::MessageBox::BASE_COLOR
      msg_window.shadowColor = EliteBattleUI::MessageBox::SHADOW_COLOR
    end
  end

  def pbShowWindow(windowType)
    ebs_nextgen_vanilla_pbShowWindow(windowType)
    return if !@battle
    hide_player_databox = (windowType == MESSAGE_BOX || windowType == FIGHT_BOX || windowType == TARGET_BOX)
    @battle.battlers.each_with_index do |b, i|
      next if !b
      next if b.opposes?(0)   # esto solo afecta al bando del jugador
      box = @sprites["dataBox_#{i}"]
      next if !box
      next if !box.respond_to?(:pbHideSliding)
      if b.fainted?
        box.pbHideSliding
        next
      end
      (hide_player_databox && !box.animating_hp?) ? box.pbHideSliding : box.pbRevealSliding
    end
    pbAdvanceMenuSlides
  end

  def pbAdvanceMenuSlides
    windows = [@sprites["commandWindow"], @sprites["fightWindow"]].compact
                                                                   .select { |w| w.respond_to?(:menu_sliding?) }
    return if windows.empty?
    loop do
      sliding = windows.select(&:menu_sliding?)
      break if sliding.empty?
      sliding.each(&:tick_menu_slide)
      pbUpdate
    end
  end

  alias_method :ebs_nextgen_vanilla_pbHPChanged, :pbHPChanged
  def pbHPChanged(battler, oldHP, showAnim = false)
    box = @sprites["dataBox_#{battler.index}"]
    box.pbRevealSliding if box && box.respond_to?(:pbRevealSliding) && !battler.opposes?(0)
    ebs_nextgen_vanilla_pbHPChanged(battler, oldHP, showAnim)
  end

  alias_method :ebs_nextgen_vanilla_pbHitAndHPLossAnimation, :pbHitAndHPLossAnimation
  def pbHitAndHPLossAnimation(targets)
    targets.each do |t|
      box = @sprites["dataBox_#{t[0].index}"]
      box.pbRevealSliding if box && box.respond_to?(:pbRevealSliding) && !t[0].opposes?(0)
    end
    ebs_nextgen_vanilla_pbHitAndHPLossAnimation(targets)
  end
end