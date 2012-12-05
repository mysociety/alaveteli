# Handles the parsing of email
require 'tmpdir'

module MailHandler

    if RUBY_VERSION.to_f >= 1.9
        require 'backends/mail_extensions'
        require 'backends/mail_backend'
        include Backends::MailBackend
    else
        require 'action_mailer'
        require 'backends/tmail_extensions'
        require 'backends/tmail_backend'
        include Backends::TmailBackend
    end

    # Returns a set of attachments from the given TNEF contents
    # The TNEF contents also contains the message body, but in general this is the
    # same as the message body in the message proper.
    def tnef_attachments(content)
        attachments = []
        Dir.mktmpdir do |dir|
            IO.popen("#{`which tnef`.chomp} -K -C #{dir}", "w") do |f|
                f.write(content)
                f.close
                if $?.signaled?
                    raise IOError, "tnef exited with signal #{$?.termsig}"
                end
                if $?.exited? && $?.exitstatus != 0
                    raise IOError, "tnef exited with status #{$?.exitstatus}"
                end
            end
            found = 0
            Dir.new(dir).sort.each do |file| # sort for deterministic behaviour
                if file != "." && file != ".."
                    file_content = File.open("#{dir}/#{file}", "r").read
                    attachments << { :content => file_content,
                                     :filename => file }
                    found += 1
                end
            end
            if found == 0
                raise IOError, "tnef produced no attachments"
            end
        end
        attachments
    end

    def normalise_content_type(content_type)
        # e.g. http://www.whatdotheyknow.com/request/93/response/250
        if content_type == 'application/excel' or content_type == 'application/msexcel' or content_type == 'application/x-ms-excel'
            content_type = 'application/vnd.ms-excel'
        end
        if content_type == 'application/mspowerpoint' or content_type == 'application/x-ms-powerpoint'
            content_type = 'application/vnd.ms-powerpoint'
        end
        if content_type == 'application/msword' or content_type == 'application/x-ms-word'
            content_type = 'application/vnd.ms-word'
        end
        if content_type == 'application/x-zip-compressed'
            content_type = 'application/zip'
        end

        # e.g. http://www.whatdotheyknow.com/request/copy_of_current_swessex_scr_opt#incoming-9928
        if content_type == 'application/acrobat'
            content_type = 'application/pdf'
        end

        return content_type
    end


    # Turn instance methods into class methods
    extend self

end

