# Handles the parsing of email
module MailHandler

    if RUBY_VERSION.to_f >= 1.9
        require 'backends/mail_backend'
        include Backends::MailBackend
    else
        require 'backends/tmail_extensions'
        require 'backends/tmail_backend'
        include Backends::TmailBackend
    end

    # Turn instance methods into class methods
    extend self

end

