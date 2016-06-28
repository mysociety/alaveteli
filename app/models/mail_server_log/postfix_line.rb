# -*- encoding : utf-8 -*-
class MailServerLog::PostfixLine
  include Comparable

  LOG_LINE_FLAGS = {
    'status=sent' =>        :sent,
    'status=deferred' =>    :deferred,
    'status=bounced' =>     :bounced,
    'status=expired' =>     :expired
  }.freeze

  def initialize(line)
    @line = line.to_s
  end

  def <=>(other)
    self.class <=> other.class && to_s <=> other.to_s
  end

  def to_s
    line
  end

  def delivery_status
    flag = LOG_LINE_FLAGS.keys.find { |flag| to_s.include?(flag) }
    status = LOG_LINE_FLAGS[flag]
    MailServerLog::PostfixDeliveryStatus.new(status) if status
  end

  def inspect
    %Q(#<#{self.class}:#{"0x00%x" % (object_id << 1)} @line="#{ line }">)
  end

  private

  attr_reader :line
end
