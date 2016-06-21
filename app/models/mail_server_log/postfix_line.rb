# -*- encoding : utf-8 -*-
class MailServerLog::PostfixLine
  include Comparable

  def initialize(line)
    @line = line.to_s
  end

  def <=>(other)
    to_s <=> other.to_s
  end

  def to_s
    line
  end

  def delivery_status
    MailServerLog::PostfixDeliveryStatus.new(:sent)
  end

  def inspect
    %Q(#<#{self.class}:#{"0x00%x" % (object_id << 1)} @line="#{ line }">)
  end

  private

  attr_reader :line
end
