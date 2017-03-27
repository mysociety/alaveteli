# -*- encoding : utf-8 -*-
class MailServerLog::DeliveryStatus
  include Comparable

  # The order of these is important as we use the keys for sorting in #<=>
  HUMANIZED = {
    :failed => _('This message could not be delivered.'),
    :sent => _('This message has been sent.'),
    :delivered => _('This message has been delivered.')
  }.freeze

  def initialize(status)
    @status = assert_valid_status(status)
  end

  def delivered?
    to_sym == :delivered
  end

  def sent?
    [:sent, :delivered].include?(to_sym)
  end

  def failed?
    to_sym == :failed
  end

  def simple
    to_sym
  end

  def humanize
    HUMANIZED[to_sym]
  end

  def <=>(other)
    a = HUMANIZED.keys.index(to_sym)
    b = HUMANIZED.keys.index(other.to_sym)
    a <=> b
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
    if HUMANIZED.keys.include?(status)
      status
    else
      raise ArgumentError, "Invalid delivery status: #{ status }"
    end
  end
end
