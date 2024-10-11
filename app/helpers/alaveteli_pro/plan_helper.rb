##
# Helper methods for formatting and displaying billing and plan information
# in the Alaveteli Pro interface
#
module AlaveteliPro::PlanHelper
  def billing_frequency(plan)
    if interval(plan) == 'day' && interval_count(plan) == 1
      _('Billed: Daily')
    elsif interval(plan) == 'week' && interval_count(plan) == 1
      _('Billed: Weekly')
    elsif interval(plan) == 'month' && interval_count(plan) == 1
      _('Billed: Monthly')
    elsif interval(plan) == 'year' && interval_count(plan) == 1
      _('Billed: Annually')
    else
      _('Billed: every {{interval}}', interval: pluralize_interval(plan))
    end
  end

  def billing_interval(plan)
    if interval_count(plan) == 1
      _('per user, per {{interval}}', interval: interval(plan))
    else
      _('per user, every {{interval}}', interval: pluralize_interval(plan))
    end
  end

  private

  def pluralize_interval(plan)
    count = interval_count(plan)
    interval = interval(plan)
    return interval if count == 1

    pluralize(count, interval)
  end

  def interval(plan)
    plan.interval
  end

  def interval_count(plan)
    plan.interval_count
  end
end
