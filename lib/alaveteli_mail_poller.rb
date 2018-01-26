# -*- encoding : utf-8 -*-
require 'net/pop'

class AlaveteliMailPoller
  include ConfigHelper

  attr_accessor :settings, :pop3

  def initialize(values = {})
    _pop3 = values.delete(:pop3)

    defaults = { address:      AlaveteliConfiguration.pop_mailer_address,
                 port:         AlaveteliConfiguration.pop_mailer_port,
                 user_name:    AlaveteliConfiguration.pop_mailer_user_name,
                 password:     AlaveteliConfiguration.pop_mailer_password,
                 enable_ssl:   AlaveteliConfiguration.pop_mailer_enable_ssl }

    self.settings = defaults.merge(values)
    self.pop3 = _pop3 || default_pop3
  end

  def poll_for_incoming
    found_mail = false
    start do |pop3|
      pop3.each_mail do |popmail|
        received = get_mail(popmail)
        found_mail = found_mail || received
      end
    end
    found_mail
  end

  # Make a poller and run poll_for_incoming in an endless loop,
  # sleeping when there is nothing to do
  def self.poll_for_incoming_loop
    if AlaveteliConfiguration.production_mailer_retriever_method == 'pop'
      poller = new
      Rails.logger.info "Starting #{ poller } polling loop"
      while true
        sleep_seconds = 1
        while !poller.poll_for_incoming
          Rails.logger.debug "#{ poller } sleeping for #{ sleep_seconds }"
          sleep sleep_seconds
          sleep_seconds *= 2
          sleep_seconds = 300 if sleep_seconds > 300
        end
      end
    end
  end

  private

  def get_mail(popmail)
    unique_id = nil
    raw_email = nil
    received = false
    begin
      unique_id = popmail.unique_id
      if retrieve?(unique_id)
        raw_email = popmail.pop
        Rails.logger.info "#{ self } retrieving #{ unique_id }"
        RequestMailer.receive(raw_email, :poller)
        received = true
        popmail.delete
      end
    rescue Net::POPError, StandardError => error
      Rails.logger.warn "#{ self } error for #{ unique_id }"
      if send_exception_notifications?
        ExceptionNotifier.notify_exception(
          error,
          :data => { mail: raw_email,
                     unique_id: unique_id }
        )
      end
      record_error(unique_id, received, error)
    end
    received
  end

  def record_error(unique_id, received, error)
    if unique_id
      retry_at = received ? nil : Time.zone.now + 30.minutes
      ime = IncomingMessageError.find_or_create_by!(unique_id: unique_id)
      ime.retry_at = retry_at
      ime.backtrace = error.backtrace.join("\n")
      ime.save!
    end
  end

  def failed?(unique_id)
    IncomingMessageError.exists?(unique_id: unique_id)
  end

  def retry?(unique_id)
    incoming_message_error = IncomingMessageError.
      where(unique_id: unique_id).take
    incoming_message_error &&
    incoming_message_error.retry_at &&
    incoming_message_error.retry_at < Time.zone.now
  end

  def retrieve?(unique_id)
    !failed?(unique_id) || retry?(unique_id)
  end

  def start(&block)
    # Start a POP3 session and ensure that it will be closed in any case.
    unless block_given?
      raise ArgumentError.new("AlaveteliMailPoller#start takes a block")
    end

    pop3.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if settings[:enable_ssl]
    pop3.start(settings[:user_name], settings[:password])

    yield pop3
  rescue Timeout::Error => error
    if send_exception_notifications?
      ExceptionNotifier.notify_exception(error)
    end
  ensure
    if defined?(pop3) && pop3 && pop3.started?
      pop3.finish
    end
  end

  def default_pop3
    Net::POP3.new(settings[:address], settings[:port], false)
  end

end
