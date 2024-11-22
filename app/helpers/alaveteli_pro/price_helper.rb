##
# Helper methods for formatting and displaying billing and price information
# in the Alaveteli Pro interface
#
module AlaveteliPro::PriceHelper
  def billing_frequency(price)
    if interval(price) == 'day' && interval_count(price) == 1
      _('Billed: Daily')
    elsif interval(price) == 'week' && interval_count(price) == 1
      _('Billed: Weekly')
    elsif interval(price) == 'month' && interval_count(price) == 1
      _('Billed: Monthly')
    elsif interval(price) == 'year' && interval_count(price) == 1
      _('Billed: Annually')
    else
      _('Billed: every {{interval}}', interval: pluralize_interval(price))
    end
  end

  def billing_interval(price)
    if interval_count(price) == 1
      _('per user, per {{interval}}', interval: interval(price))
    else
      _('per user, every {{interval}}', interval: pluralize_interval(price))
    end
  end

  private

  def pluralize_interval(price)
    count = interval_count(price)
    interval = interval(price)
    return interval if count == 1

    pluralize(count, interval)
  end

  def interval(price)
    price.recurring['interval']
  end

  def interval_count(price)
    price.recurring['interval_count']
  end
end
