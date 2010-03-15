require 'tmpdir'

class TNEF

    # Extracts all attachments from the given TNEF file as a TMail::Mail object
    # The TNEF file also contains the message body, but in general this is the
    # same as the message body in the message proper.
    def self.as_tmail(content)
        main = TMail::Mail.new
        main.set_content_type 'multipart', 'mixed', { 'boundary' => TMail.new_boundary }
        Dir.mktmpdir do |dir|
            IO.popen("tnef -K -C #{dir}", "w") do |f|
                f.write(content)
                f.close
                if $?.signaled?
                    raise IOError, "tnef exited with signal #{$?.termsig}"
                end
                if $?.exited? && $?.exitstatus != 0
                    raise IOError, "tnef exited with status #{$?.exitstatus}"
                end
            end
            Dir.new(dir).sort.each do |file| # sort for deterministic behaviour
                if file != "." && file != ".."
                    file_content = File.open("#{dir}/#{file}", "r").read
                    attachment = TMail::Mail.new
                    attachment['content-location'] = file
                    attachment.body = file_content
                    main.parts << attachment
                end
            end
        end
        main
    end

end
