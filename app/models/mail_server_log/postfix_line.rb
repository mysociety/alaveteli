# -*- encoding : utf-8 -*-
class MailServerLog::PostfixLine
  include Comparable

  LOG_LINE_FLAGS = {
    'status=sent' => :sent,
    'status=deferred' => :deferred,
    'status=bounced' => :bounced,
    'status=expired' => :expired
  }.freeze

  DELIVERED_FLAGS = [
    :sent
  ].freeze

  SENT_FLAGS = [
    :deferred
  ].freeze

  FAILED_FLAGS = [
    :bounced,
    :expired
  ].freeze

  def initialize(line)
    @line = line.to_s
  end

  # Public: The Exim log flag parsed from the log line
  #
  # Returns a String
  def flag
    LOG_LINE_FLAGS.keys.find { |flag| to_s.include?(flag) }
  end

  # Public: The human-readable meaning of the #flag
  #
  # Returns a Symbol
  def status
    LOG_LINE_FLAGS[flag]
  end

  # Public: A value object encapsulating generic delivery status information
  #
  # Returns a MailServerLog::DeliveryStatus
  def delivery_status
    MailServerLog::DeliveryStatus.new(parse_delivery_status)
  end

  def <=>(other)
    self.class <=> other.class && to_s <=> other.to_s
  end

  def to_s
    line
  end

  def inspect
    %Q(#<#{self.class}:#{format("0x00%x", (object_id << 1))} @line="#{ line }">)
  end

  private

  attr_reader :line

  def parse_delivery_status
    case status
    when nil?
      :unknown
    when *DELIVERED_FLAGS
      :delivered
    when *SENT_FLAGS
      :sent
    when *FAILED_FLAGS
      :failed
    else
      :unknown
    end
  end
end
