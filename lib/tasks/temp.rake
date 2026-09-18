include AlaveteliFeatures::Helpers

namespace :temp do
  desc 'Populate User#status_update_count'
  task populate_user_status_update_count: :environment do
    scope = User.all
    count = scope.count

    scope.find_each.with_index do |user, index|
      update_count = InfoRequestEvent.
        where(event_type: 'status_update').
        where("params -> 'user' ->> 'gid' = ?", user.to_gid.to_s).
        count

      user.update_columns(status_update_count: update_count)

      erase_line
      print "Populating User#status_update_count #{index + 1}/#{count}"
    end

    erase_line
    puts "Populating User#status_update_count completed."
  end

  desc "Encrypt users' existing plaintext otp_secret_key"
  task encrypt_user_otp_secret_keys: :environment do
    # otp_secret_key predates Active Record Encryption, so existing rows hold
    # the secret in plaintext. #encrypt re-saves each user's encrypted columns
    # in place. support_unencrypted_data keeps unencrypted rows readable until
    # this has run, so it can be run out of band after deploying and re-run
    # safely.
    scope = User.where.not(otp_secret_key: nil)
    count = scope.count

    scope.find_each.with_index do |user, index|
      user.encrypt

      erase_line
      print "Encrypting otp_secret_key #{index + 1}/#{count}"
    end

    erase_line
    puts "Encrypting otp_secret_key completed."
  end

  desc 'Record redactions made to existing content by current CensorRules'
  task record_censor_rule_redactions: :environment do
    # CensorRule::Redaction rows are only written as a rule is applied, so
    # content redacted before the tracking existed has nothing recorded
    # against it. Expire each affected request to drop the cached (already
    # redacted) content, then read each redactable attribute back so the
    # masking pipeline runs again and records what it removes.
    #
    # Safe to re-run and can be picked up from a given request with START_AT.
    unless feature_enabled?(:redaction_tracking)
      abort 'The :redaction_tracking feature must be enabled to run this task'
    end

    start_at = (ENV['START_AT'] || 0).to_i
    scope = requests_with_censor_rules.where(id: start_at..).order(:id)
    count = scope.count
    errors = []

    scope.find_each.with_index do |info_request, index|
      info_request.expire

      record_redactions(info_request, errors)

      erase_line
      print "Recording CensorRule redactions #{index + 1}/#{count} " \
            "(InfoRequest##{info_request.id})"
    end

    erase_line
    puts "Recording CensorRule redactions completed."

    next if errors.empty?

    puts "#{errors.count} record(s) could not be re-redacted:"
    errors.each { |error| puts "  #{error}" }
  end

  # InfoRequests that at least one CensorRule applies to. A global rule covers
  # every request, otherwise collect the requests that each rule could apply to.
  def requests_with_censor_rules
    return InfoRequest.unscoped if CensorRule.global.exists?

    ids = CensorRule.find_each.flat_map { it.censorable_requests.ids }.uniq
    InfoRequest.where(id: ids)
  end

  # Read each attribute the masking pipeline redacts, so that applying the
  # rules records what they remove.
  #
  # Attachments already locked can't be backfilled as locking freezes their
  # content. Anything locked from now on records its redactions as part of
  # locking, applying the rules while the attachment is still mutable.
  def record_redactions(info_request, errors)
    attempt(errors, info_request) { info_request.safe_from_name }

    info_request.outgoing_messages.find_each do |message|
      attempt(errors, message) do
        message.safe_from_name
        message.body
      end
    end

    info_request.incoming_messages.find_each do |message|
      attempt(errors, message) do
        message.safe_from_name
        message.get_main_body_text_unfolded
      end

      message.foi_attachments.each do |attachment|
        attempt(errors, attachment) do
          attachment.redacted_filename
          attachment.body
        end
      end

      # Text extracted from the attachments is masked separately from their
      # bodies, and tracked separately, so it needs driving in its own right.
      attempt(errors, message) { message.get_attachment_text_full }
    end
  end

  # Erased raw emails, missing attachments and masking failures are expected
  # in a corpus this old, so collect them rather than aborting the run.
  def attempt(errors, record)
    yield
  rescue StandardError => e
    errors << "#{record.class}##{record.id}: #{e.class}: #{e.message}"
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end
