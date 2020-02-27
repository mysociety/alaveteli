class MailServerLog::DeliveryStatusSerializer
  # Public: Tries to load the cached delivery_status value from the database
  #
  # value - The String representation of the delivery status, as held in the
  #         database (e.g 'sent', 'rejected', 'failed')
  #
  # Returns a MailServerLog::DeliveryStatus, or nil if the value is not stored
  def self.load(value)
    if value.is_a?(String)
      MailServerLog::DeliveryStatus.new(value.to_sym)
    else
      value
    end
  end

  # Public: Casts the DeliveryStatus to a String so it can be stored in
  # the database.
  #
  # value - a MailServerLog::DeliveryStatus log line's delivery status
  #
  # Returns a String or nil
  def self.dump(value)
    return unless value
    value.to_s
  end
end
