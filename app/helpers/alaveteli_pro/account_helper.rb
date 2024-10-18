module AlaveteliPro::AccountHelper
  def card_expiry_message(month, year)
    if month == Date.today.month && year == Date.today.year
      content_tag(:p, _('Expires soon'), class: 'card__expiring')
    end
  end
end
