# Handles the parsing of email
require 'English'
require 'tmpdir'

module MailHandler
  require 'mail'
  require 'mail_handler/backends/mail_extensions'
  require 'mail_handler/backends/mail_backend'
  include Backends::MailBackend

  class TNEFParsingError < StandardError
  end

  # Returns a set of attachments from the given TNEF contents
  # The TNEF contents also contains the message body, but in general this is the
  # same as the message body in the message proper.
  def tnef_attachments(content)
    attachments = []
    Dir.mktmpdir do |dir|
      IO.popen("tnef -K -C #{dir} 2> /dev/null", "wb") do |f|
        f.write(content)
        f.close
        raise IOError, "tnef exited with signal #{$CHILD_STATUS.termsig}" if $CHILD_STATUS.signaled?
        if $CHILD_STATUS.exited? && $CHILD_STATUS.exitstatus != 0
          raise TNEFParsingError, "tnef exited with status #{$CHILD_STATUS.exitstatus}"
        end
      end
      found = 0
      Dir.new(dir).sort.each do |file| # sort for deterministic behaviour
        if file != "." && file != ".."
          file_content = File.open("#{dir}/#{file}", "rb").read
          attachments << { content: file_content,
                           filename: file }
          found += 1
        end
      end
      raise TNEFParsingError, "tnef produced no attachments" if found == 0
    end
    attachments
  end

  def normalise_content_type(content_type)
    # e.g. http://www.whatdotheyknow.com/request/93/response/250
    if (content_type == 'application/excel') || (content_type == 'application/msexcel') || (content_type == 'application/x-ms-excel')
      content_type = 'application/vnd.ms-excel'
    end
    if (content_type == 'application/mspowerpoint') || (content_type == 'application/x-ms-powerpoint')
      content_type = 'application/vnd.ms-powerpoint'
    end
    if (content_type == 'application/msword') || (content_type == 'application/x-ms-word')
      content_type = 'application/vnd.ms-word'
    end
    if content_type == 'application/x-zip-compressed'
      content_type = 'application/zip'
    end

    # e.g. http://www.whatdotheyknow.com/request/copy_of_current_swessex_scr_opt#incoming-9928
    if (content_type == 'application/acrobat') || (content_type == 'document/pdf')
      content_type = 'application/pdf'
    end

    content_type
  end

  # Turn instance methods into class methods
  extend self
end
