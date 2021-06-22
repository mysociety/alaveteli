# -*- encoding : utf-8 -*-
# -*- SkipSchemaAnnotations
class MailServerLog::PostfixDeliveryStatus
  module TranslatedConstants

    def self.humanized
      {
        :delivered => _('This message has been delivered.'),
        :failed => _('This message could not be delivered.'),
        :sent => _('This message has been sent.')
      }.freeze
    end

  end
end
