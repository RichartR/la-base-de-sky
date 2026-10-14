
#===============================================================================
class Battle::Scene::FightMenu
  alias_method :ebs_nextgen_vanilla_addSpecialActionButtons, :addSpecialActionButtons
  def addSpecialActionButtons(path)
    ebs_nextgen_vanilla_addSpecialActionButtons(path)
    return if !@actionButtonBitmap.is_a?(Hash)
    EliteBattleUI::SpecialButtons::CURSOR_FILES.each do |key, filename|
      next if !@actionButtonBitmap.key?(key)
      nextgen_path = GRAPHICS_PATH + filename
      next if !pbResolveBitmap(nextgen_path)
      @actionButtonBitmap[key]&.dispose
      @actionButtonBitmap[key] = AnimatedBitmap.new(nextgen_path)
    end
  end
end
