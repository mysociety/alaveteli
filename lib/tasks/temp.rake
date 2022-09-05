namespace :temp do
  desc 'Migrate PublicBody notes into Note model'
  task migrate_public_body_notes: :environment do
    scope = PublicBody.where.not(notes: nil)
    count = scope.count

    scope.with_translations.find_each.with_index do |body, index|
      PublicBody.transaction do
        body.legacy_note&.save
        body.translations.update(notes: nil)
      end

      erase_line
      print "Migrated PublicBody#notes #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrated PublicBody#notes completed."
  end

  desc 'Populate incoming message from email'
  task populate_incoming_message_from_email: :environment do
    scope = IncomingMessage.where(from_email: nil)
    count = scope.count

    scope.includes(:raw_email).find_each.with_index do |message, index|
      message.update_columns(from_email: message.raw_email.from_email || '')

      erase_line
      print "Populated IncomingMessage#from_email #{index + 1}/#{count}"
    end

    erase_line
    puts "Populated IncomingMessage#from_email completed."
  end

  desc 'Remove raw email records not assoicated with an incoming message'
  task remove_orphan_raw_email_records: :environment do
    RawEmail.left_joins(:incoming_message).
      where(incoming_messages: { id: nil }).
      delete_all
  end

  desc 'Fix invalid embargo attributes'
  task nullify_empty_embargo_durations: :environment do
    classes_attributes = {
      AlaveteliPro::DraftInfoRequestBatch => :embargo_duration,
      InfoRequestBatch => :embargo_duration,
      ProAccount => :default_embargo_duration
    }

    classes_attributes.each do |klass, attr|
      puts "Updating #{klass}##{attr}"
      klass.where(attr => '').update_all(attr => nil)
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

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end
