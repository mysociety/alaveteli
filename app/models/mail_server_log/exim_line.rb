# -*- encoding : utf-8 -*-
class MailServerLog::EximLine
  include Comparable

  # http://www.exim.org/exim-html-current/doc/html/spec_html/ch-log_files.html#SECID250
  # WARNING: The order of the :bounce_arrival and :message_arrival keys is
  # important. A :bounce_arrival can incorrectly get parsed as a
  # :message_arrival given that it includes the <= symbol.
  # TODO: Make parsing of EximLine flag more intelligent
  LOG_LINE_FLAGS = {
    '<= <>' => :bounce_arrival,
    '<=' => :message_arrival,
    '=>' => :normal_message_delivery,
    '->' => :additional_address_in_same_delivery,
    '>>' => :cutthrough_message_delivery,
    '*>' => :delivery_suppressed_by_N,
    '**' => :delivery_failed_address_bounced,
    '==' => :delivery_deferred_temporary_problem
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
    MailServerLog::DeliveryStatus.new(parse_delivery_status) if status
  end

  def <=>(other)
    self.class <=> other.class && to_s <=> other.to_s
  end

  def to_s
    line
  end

  def inspect
    %Q(#<#{self.class}:#{"0x00%x" % (object_id << 1)} @line="#{ line }">)
  end

  private

  attr_reader :line

  def parse_delivery_status
    case status
    when *DELIVERED_FLAGS
      :delivered
    when *SENT_FLAGS
      :sent
    when *FAILED_FLAGS
      :failed
    end
  end
end
