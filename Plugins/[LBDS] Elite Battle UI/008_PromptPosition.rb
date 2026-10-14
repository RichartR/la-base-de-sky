class Battle::Scene::EnhancedUIPrompt
  FIXED_Y_OFFSET = -46

  alias_method :ebs_nextgen_vanilla_initialize, :initialize
  def initialize(battler, battle, window, viewport = nil)
    ebs_nextgen_vanilla_initialize(battler, battle, window, viewport)
    self.y = 236 + FIXED_Y_OFFSET
  end

  alias_method :ebs_nextgen_vanilla_refresh, :refresh
  def refresh
    ebs_nextgen_vanilla_refresh
    self.y = 236 + FIXED_Y_OFFSET
  end
end
