# -*- encoding : utf-8 -*-
class MailServerLog::EximDeliveryStatus
  include Comparable

  HUMANIZED = {
    :delivered => _('This message has been delivered.'),
    :failed => _('This message could not be delivered.'),
    :sent => _('This message has been sent.')
  }.freeze

  DELIVERED_FLAGS = [
    :normal_message_delivery,
    :additional_address_in_same_delivery,
    :cutthrough_message_delivery
  ].freeze

  SENT_FLAGS = [
    :message_arrival,
    :delivery_deferred_temporary_problem
  ].freeze

  FAILED_FLAGS = [
    :bounce_arrival,
    :delivery_suppressed_by_N,
    :delivery_failed_address_bounced
  ].freeze

  MTA_FLAGS = (DELIVERED_FLAGS | SENT_FLAGS | FAILED_FLAGS).freeze

  def initialize(status)
    @status = assert_valid_status(status)
  end

  def delivered?
    simple == :delivered
  end

  def sent?
    simple == :sent
  end

  def failed?
    simple == :failed
  end

  def simple
    case status
    when *DELIVERED_FLAGS
      :delivered
    when *SENT_FLAGS
      :sent
    when *FAILED_FLAGS
      :failed
    end
  end

  def humanize
    HUMANIZED[simple]
  end

  def <=>(other)
    to_sym <=> other.to_sym
  end

  def to_sym
    status
  end

  def to_s
    status.to_s
  end

  def inspect
    obj_id = "0x00%x" % (object_id << 1)
    %Q(#<#{self.class}:#{obj_id} @status=:#{ status }>)
  end

  private

  attr_reader :status

  def assert_valid_status(status)
    if MTA_FLAGS.include?(status)
      status
    else
      raise ArgumentError, "Invalid MTA status: #{ status }"
    end
  end
end
