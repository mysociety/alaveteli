# -*- encoding : utf-8 -*-
class OutgoingMessage
  module Template
    class InitialRequest
      def body(opts = {})
        assert_required_keys(opts, :public_body_name)
        template_string(opts)
      end

      def self.placeholder_salutation
        _('Dear {{placeholder_body_name}},',
          placeholder_body_name: placeholder_body_name)
      end

      # Separate so that it can be referred to directly elsewhere (e.g. to
      # pass to javascript functions that have to replicate placeholders)
      def self.placeholder_body_name
        _('[Authority name]')
      end

      def salutation(replacements = {})
        if replacements[:public_body_name]
          _("Dear {{public_body_name}},", replacements)
        else
          self.class.placeholder_salutation
        end
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

      def assert_required_keys(hash, *required_keys)
        required_keys.each do |required_key|
          unless hash.key?(required_key)
            raise ArgumentError, "Missing required key: #{required_key}"
          end
        end
      end
    end
  end
end
