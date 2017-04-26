# -*- encoding : utf-8 -*-
class MailServerLog::DeliveryStatus
  module TranslatedConstants

    def self.humanized
      # The order of these is important as we use the keys for sorting in #<=>
      {
        :unknown => _("We don't know the delivery status for this message."),
        :failed => _('This message could not be delivered.'),
        :sent => _('This message has been sent.'),
        :delivered => _('This message has been delivered.')
      }.freeze
    end

  end
end
