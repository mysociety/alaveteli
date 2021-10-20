namespace :temp do
  desc 'Re-parse attachments affected by mysociety/alaveteli#5905'
  task reparse_multipart_incoming_with_unicode: :environment do
    since = ENV.fetch('FROM_DATE', Date.parse('2020-08-10'))

    IncomingMessage.
      where('created_at > ?', since).
      where("cached_main_body_text_folded ILIKE '%Content-Type%'").
      find_each do |message|
        message.clear_in_database_caches! && message.parse_raw_email!(true)
      end
  end

  desc 'Re-parse attachments affected by mysociety/alaveteli#5905'
  task reparse_multipart_incoming_with_unicode: :environment do
    since = ENV.fetch('FROM_DATE', Date.parse('2020-08-10'))

    IncomingMessage.
      where('created_at > ?', since).
      where("cached_main_body_text_folded ILIKE '%Content-Type%'").
      find_each do |message|
        message.clear_in_database_caches! && message.parse_raw_email!(true)
      end
  end

  desc 'Identify broken binary censor rules'
  task identify_broken_binary_censor_rules: :environment do
    helper = ApplicationController.helpers
    helper.class_eval { include Rails.application.routes.url_helpers }

    module ConfigHelper
      def send_exception_notifications?
        false
      end
    end

    # 0.37.0.0 broken implementation of CensorRule#apply_to_binary
    # Need to monkeypatch it here to cause the error when searching the affected
    # attachments.
    CensorRule.class_eval do
      def apply_to_binary(binary_to_censor)
        return nil if binary_to_censor.nil?
        binary_to_censor.gsub(to_replace('ASCII-8BIT')) do |match|
          match.gsub(single_char_regexp, 'x')
        end
      end
    end

    ApplicationController.allow_forgery_protection = false
    app = ActionDispatch::Integration::Session.new(Rails.application)
    checked_attachments = []

    CensorRule.find_each do |rule|
      rule.censorable_requests.find_each do |info_request|
        next unless info_request.foi_attachments.binary.any?

        info_request.foi_attachments.binary.find_each do |attachment|
          params =
            helper.
            send(:attachment_params, attachment, html: true, only_path: true)

          next if checked_attachments.include?(attachment.id)

          path = helper.get_attachment_as_html_url(params)
          protocol = AlaveteliConfiguration.force_ssl ? 'https' : 'http'
          domain = AlaveteliConfiguration.domain
          url = "#{protocol}://#{domain}#{path}?skip_cache=#{rand}"

          app.get(url)

          if app.response.code == '500'
            puts url
          end

          checked_attachments << attachment.id
        end
      end
    end
  end

  desc 'Create InfoRequestEvents for each requests made by an active paying ' \
       'pro subscriber'
  task record_pro_requests: :environment do
    next unless AlaveteliFeatures.backend.enabled?(:pro_pricing)

    ProAccount.find_each do |pro_account|
      user = pro_account.user
      info_requests = user.info_requests

      next if info_requests.count == 0
      next if info_requests.any? do |r|
        r.info_request_events.where(event_type: 'pro').any?
      end

      subscriptions = Stripe::Subscription.list(
        status: 'all', customer: pro_account.stripe_customer_id
      )

      ranges = subscriptions.map do |s|
        started_at = Time.at(s.created)
        ended_at = Time.at(s.ended_at) if s.ended_at
        ended_at ||= Time.now

        started_at..ended_at
      end

      info_requests.where(created_at: ranges).find_each do |request|
        request.log_event('pro', {}, created_at: request.created_at)
      end
    end
  end
end
