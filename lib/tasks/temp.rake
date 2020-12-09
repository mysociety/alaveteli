# -*- coding: utf-8 -*-
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
end
