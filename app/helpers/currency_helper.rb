module CurrencyHelper
  def format_currency(amount)
    Money.new(amount, AlaveteliConfiguration.iso_currency_code).format
  end
end
