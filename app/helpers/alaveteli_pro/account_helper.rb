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

  def card_expiry_message(month, year)
    if month == Date.today.month && year == Date.today.year
      content_tag(:p, _('Expires soon'), class: 'card__expiring')
    end
  end

  def subscription_amount(subscription)
    AlaveteliPro::WithTax.new(subscription).amount_with_tax
  end

end
