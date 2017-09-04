# -*- encoding : utf-8 -*-
module AlaveteliPro::AccountHelper

  def billing_frequency(billing_unit)
    case billing_unit
    when 'day'
      _('Billed: Daily')
    when 'week'
      _('Billed: Weekly')
    when 'month'
      _('Billed: Monthly')
    when 'year'
      _('Billed: Annually')
    end
  end

end
