# -*- encoding : utf-8 -*-
class MailServerLog::PostfixDeliveryStatus
  include Comparable

  def initialize(status = :sent)
    @status = :sent
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
    :sent
  end

  def humanize
    _('This message has been sent.')
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
    %Q(#<#{self.class}:#{obj_id} @status=:#{status}>)
  end

  private

  attr_reader :status
end
