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

  def initialize(line)
    @line = line.to_s
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

  def delivery_status
    flag = LOG_LINE_FLAGS.keys.find { |flag| to_s.include?(flag) }
    status = LOG_LINE_FLAGS[flag]
    MailServerLog::EximDeliveryStatus.new(status) if status
  end

  private

  attr_reader :line
end
