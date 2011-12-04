# Monkeypatch!
# Grrr, semantics of smtp and sendmail send should be the same with regard to setting return path

# See test in spec/lib/sendmail_return_path_spec.rb

module ActionMailer
   class Base
      def perform_delivery_sendmail(mail)
        sender = (mail['return-path'] && mail['return-path'].spec) || mail.from.first

        sendmail_args = sendmail_settings[:arguments].dup
        sendmail_args += " -f \"#{sender}\""

        IO.popen("#{sendmail_settings[:location]} #{sendmail_args}","w+") do |sm|
          sm.print(mail.encoded.gsub(/\r/, ''))
          sm.flush
        end
      end
   end
end

