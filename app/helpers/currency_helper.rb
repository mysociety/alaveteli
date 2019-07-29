module CurrencyHelper
  def format_currency(amount, no_cents_if_whole: false)
    Money.new(amount, AlaveteliConfiguration.iso_currency_code).
      format(no_cents_if_whole: no_cents_if_whole)
  end
end
