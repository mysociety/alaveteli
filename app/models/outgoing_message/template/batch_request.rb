# -*- encoding : utf-8 -*-
class OutgoingMessage
  module Template
    class BatchRequest
      def self.placeholder_salutation
        _('Dear [Authority name],')
      end

      def body(opts = {})
        template_string(opts)
      end

      def salutation(replacements = {})
        self.class.placeholder_salutation
      end

      def letter(replacements = {})
        if replacements[:letter]
          "\n\n#{ replacements[:letter] }"
        else
          ''
        end
      end

      def signoff(replacements = {})
        _("Yours faithfully,", replacements)
      end

      private

      def template_string(replacements)
        msg = salutation(replacements)
        msg += letter(replacements)
        msg += "\n\n\n\n"
        msg += signoff(replacements)
        msg += "\n\n"
      end

    end
  end
end
