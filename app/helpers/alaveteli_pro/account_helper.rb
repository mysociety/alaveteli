# -*- encoding : utf-8 -*-
module AlaveteliPro::AccountHelper

  def billing_frequency(billing_unit)
    case billing_unit
    when 'day'
      _('Daily')
    when 'week'
      _('Weekly')
    when 'month'
      _('Monthly')
    when 'year'
      _('Annually')
    end
  end

end
