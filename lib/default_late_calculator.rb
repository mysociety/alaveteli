# -*- encoding : utf-8 -*-
class DefaultLateCalculator
  def self.description
    %q(Defaults controlled by config/general.yml)
  end

  def reply_late_after_days
    AlaveteliConfiguration.reply_late_after_days
  end

  def reply_very_late_after_days
    AlaveteliConfiguration.reply_very_late_after_days
  end
end
