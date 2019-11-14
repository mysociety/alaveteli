module AlaveteliPro
  ##
  # A class to encapsulate composing a data structure of reporting data for
  # Pro user activity from a mix of database and Stripe API sources
  class MetricsReport
    include AlaveteliFeatures::Helpers

    attr_reader :report_start, :report_end

    def initialize
      @report_start = 1.week.ago.beginning_of_week
      @report_end = 1.weeks.ago.end_of_week
    end

    def report_period
      report_start..report_end
    end

    def includes_pricing_data?
      feature_enabled?(:pro_pricing)
    end

    def report_data
      data =
        {
          new_pro_requests: number_of_requests_created_this_week,
          estimated_total_pro_requests: estimated_number_of_pro_requests,
          new_batches: number_of_batch_requests_created_this_week,
          new_signups: number_of_pro_signups_this_week,
          total_accounts: total_number_of_pro_accounts,
          active_accounts: number_of_pro_accounts_active_this_week,
          expired_embargoes: number_of_expired_embargoes_this_week
        }

      data.merge!(stripe_report_data) if includes_pricing_data?
      data
    end

    def stripe_report_data
      return {} unless includes_pricing_data?

      data =
        {
          paying_users: stripe_data[:paid],
          discounted_users: stripe_data[:discount],
          trialing_users: stripe_data[:trialing],
          past_due_users: {
            count: stripe_data[:past_due],
            subs:  stripe_data[:past_due_users]
          },
          pending_cancellations: {
            count: stripe_data[:canceled],
            subs:  stripe_data[:canceled_users]
          },
          unknown_users: stripe_data[:unknown]
        }

      data.merge!(new_stripe_users)
      data.merge!(cancelled_stripe_users)
      data
    end

    private

    def number_of_requests_created_this_week
      InfoRequest.pro.where(created_at: report_period).count
    end

    def estimated_number_of_pro_requests
      User.where(id: ProAccount.pluck(:user_id)).map.sum do |user|
        # TODO: also scope to subscription closed_at
        user.info_requests.
          where('created_at >= ?', user.pro_account.created_at).
            count
      end
    end

    def number_of_batch_requests_created_this_week
      InfoRequestBatch.
        where(created_at: report_period).where.not(embargo_duration: nil).count
    end

    def number_of_pro_signups_this_week
      ProAccount.where(created_at: report_period).count
    end

    def total_number_of_pro_accounts
      ProAccount.count
    end

    def number_of_pro_accounts_active_this_week
      events = %w(comment set_embargo sent followup_sent status_update)

      User.pro.joins(:info_request_events).
        where(info_request_events: {
                created_at: report_period,
                event_type: events
              }).distinct.count
    end

    def number_of_expired_embargoes_this_week
      InfoRequest.not_embargoed.joins(:info_request_events).
        where(info_request_events: {
                event_type: 'expire_embargo',
                created_at: report_period
              }).distinct.count
    end

    def stripe_plans
      prefix =
        if AlaveteliConfiguration.stripe_namespace.blank?
          ''
        else
          "#{AlaveteliConfiguration.stripe_namespace}-"
        end
      ["#{prefix}pro", "#{prefix}pro-annual-billing"]
    end

    def new_stripe_users
      count = 0
      sub_ids = []
      stripe_plans.each do |plan_id|
        begin
          Stripe::Subscription.list(
            'created[gte]': report_start.to_i,
            'created[lte]': report_end.to_i,
            plan: plan_id
          ).auto_paging_each do |item|
            if item.plan.id == plan_id
              count += 1
              sub_ids << item.id
            end
          end
        rescue Stripe::InvalidRequestError
          # tried to fetch a plan that's not set up
        end
      end
      { new_and_returning_users: { count: count, subs: sub_ids } }
    end

    def cancelled_stripe_users
      count = 0
      sub_ids = []
      list = Stripe::Event.list(
        'created[gte]': report_start.to_i,
        'created[lte]': report_end.to_i,
        'type': 'customer.subscription.deleted'
      ).auto_paging_each do |item|
        # there's no filter for plan in the Event API so we need to ignore
        # any cancellations which aren't ours
        if stripe_plans.include?(item.data.object.plan.id)
          count += 1
          sub_ids << item.data.object.id
        end
      end

      { canceled_users: { count: count, subs: sub_ids } }
    end

    def append_sub(memo, sub)
      if memo == 0
        [sub.id]
      else
        memo << sub.id
      end
    end

    def stripe_data
      @wdtk_subs ||=
        Stripe::Subscription.list.auto_paging_each.
          select { |s| stripe_plans.include?(s.plan.id) }.
            each_with_object(Hash.new(0)) do |sub, memo|
              if sub.status == 'canceled' || sub.cancel_at_period_end
                memo[:canceled] += 1
                memo[:canceled_users] = append_sub(memo[:canceled_users], sub)
              elsif sub.status == 'active' && !sub.discount
                memo[:paid] += 1
              elsif sub.status == 'active' && sub.discount
                memo[:discount] += 1
              elsif sub.status == 'trialing'
                memo[:trialing] += 1
              elsif sub.status == 'past_due'
                memo[:past_due] += 1
                memo[:past_due_users] = append_sub(memo[:past_due_users], sub)
              else
                # Shouldn't ever be > 0
                memo[:unknown] += 1
              end
            end
    end
  end
end
