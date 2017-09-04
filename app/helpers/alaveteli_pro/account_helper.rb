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

  def card_expiry_message(month, year)
    if month == Date.today.month && year == Date.today.year
      _('Expires soon')
    end
  end

  def card_default_message(source, default_id)
    if source == default_id
      _('Default')
    end
  end

end
