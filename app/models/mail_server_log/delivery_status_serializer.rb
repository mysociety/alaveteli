class MailServerLog::DeliveryStatusSerializer
  # Public: Tries to load the cached delivery_status value from the database
  #
  # value - The String representation of the delivery status, as held in the
  #         database (e.g 'sent', 'rejected', 'failed')
  #
  # Returns the appropriate DeliveryStatus class depending on which MTA is
  # in use (so currently a MailServerLog::EximDeliveryStatus or a
  # MailServerLog::PostfixDeliveryStatus object). Or nil, if the value
  # is not stored
  def self.load(value)
    if value.is_a?(String)
      delivery_status_class.new(value.to_sym)
    else
      value
    end
  end


  # Public: Casts the delivery_status object to a String so it can be stored in
  # the database.
  #
  # value - a MailServerLog::EximDeliveryStatus or
  #         MailServerLog::PostfixDeliveryStatus object representing the
  #         message log line's delivery status
  #
  # Returns a String or nil
  def self.dump(value)
    return unless value
    # Both delivery status classes return the MTA status Symbol as a String:
    value.to_s
  end

  private

  def self.delivery_status_class
    mta = AlaveteliConfiguration.mta_log_type.to_sym
    case mta
    when :exim
      MailServerLog::EximDeliveryStatus
    when :postfix
      MailServerLog::PostfixDeliveryStatus
    else
      raise "Unexpected MTA type: #{ mta }"
    end
  end
end
