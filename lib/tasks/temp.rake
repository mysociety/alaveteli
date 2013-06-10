namespace :temp do

    desc 'Create a CSV file of a random selection of raw emails, for comparing hexdigests'
    task :random_attachments_hexdigests => :environment do

        # The idea is to run this under the Rail 2 codebase, where
        # Tmail was used to extract the attachements, and the task
        # will output all of those file paths in a CSV file, and a
        # list of the raw email files in another.  The latter file is
        # useful so that one can easily tar up the emails with:
        #
        #   tar cvz -T raw-email-files -f raw_emails.tar.gz
        #
        # Then you can switch to the Rails 3 codebase, where
        # attachment parsing is done via
        # recompute_attachments_hexdigests

        require 'csv'

        File.open('raw-email-files', 'w') do |f|
            CSV.open('attachment-hexdigests.csv', 'w') do |csv|
                csv << ['filepath', 'i', 'url_part_number', 'hexdigest']
                IncomingMessage.all(:order => 'RANDOM()', :limit => 1000).each do |incoming_message|
                    # raw_email.filepath fails unless the
                    # incoming_message has an associated request
                    next unless incoming_message.info_request
                    raw_email = incoming_message.raw_email
                    f.puts raw_email.filepath
                    incoming_message.foi_attachments.each_with_index do |attachment, i|
                        csv << [raw_email.filepath, i, attachment.url_part_number, attachment.hexdigest]
                    end
                end
            end
        end

    end


    desc 'Check the hexdigests of attachments in emails on disk'
    task :recompute_attachments_hexdigests => :environment do

        require 'csv'
        require 'digest/md5'

        OldAttachment = Struct.new :filename, :attachment_index, :url_part_number, :hexdigest

        filename_to_attachments = Hash.new {|h,k| h[k] = []}

        header_line = true
        CSV.foreach('attachment-hexdigests.csv') do |filename, attachment_index, url_part_number, hexdigest|
            if header_line
                header_line = false
            else
                filename_to_attachments[filename].push OldAttachment.new filename, attachment_index, url_part_number, hexdigest
            end
        end

        total_attachments = 0
        attachments_with_different_hexdigest = 0
        files_with_different_numbers_of_attachments = 0
        no_tnef_attachments = 0
        no_parts_in_multipart = 0

        multipart_error = "no parts on multipart mail"
        tnef_error = "tnef produced no attachments"

        # Now check each file:
        filename_to_attachments.each do |filename, old_attachments|

            # Currently it doesn't seem to be possible to reuse the
            # attachment parsing code in Alaveteli without saving
            # objects to the database, so reproduce what it does:

            raw_email = nil
            File.open(filename) do |f|
                raw_email = f.read
            end
            mail = MailHandler.mail_from_raw_email(raw_email)

            begin
                attachment_attributes = MailHandler.get_attachment_attributes(mail)
            rescue IOError => e
                if e.message == tnef_error
                    puts "#{filename} #{tnef_error}"
                    no_tnef_attachments += 1
                    next
                else
                    raise
                end
            rescue Exception => e
                if e.message == multipart_error
                    puts "#{filename} #{multipart_error}"
                    no_parts_in_multipart += 1
                    next
                else
                    raise
                end
            end

            if attachment_attributes.length != old_attachments.length
                puts "#{filename} the number of old attachments #{old_attachments.length} didn't match the number of new attachments #{attachment_attributes.length}"
                files_with_different_numbers_of_attachments += 1
            else
                old_attachments.each_with_index do |old_attachment, i|
                    total_attachments += 1
                    attrs = attachment_attributes[i]
                    old_hexdigest = old_attachment.hexdigest
                    new_hexdigest = attrs[:hexdigest]
                    new_content_type = attrs[:content_type]
                    old_url_part_number = old_attachment.url_part_number.to_i
                    new_url_part_number = attrs[:url_part_number]
                    if old_url_part_number != new_url_part_number
                        puts "#{i} #{filename} old_url_part_number #{old_url_part_number}, new_url_part_number #{new_url_part_number}"
                    end
                    if old_hexdigest != new_hexdigest
                        body = attrs[:body]
                        # First, if the content type is one of
                        # text/plain, text/html or application/rtf try
                        # changing CRLF to LF and calculating a new
                        # digest - we generally don't worry about
                        # these changes:
                        new_converted_hexdigest = nil
                        if ["text/plain", "text/html", "application/rtf"].include? new_content_type
                            converted_body = body.gsub /\r\n/, "\n"
                            new_converted_hexdigest = Digest::MD5.hexdigest converted_body
                            puts "new_converted_hexdigest is #{new_converted_hexdigest}"
                        end
                        if (! new_converted_hexdigest) || (old_hexdigest != new_converted_hexdigest)
                            puts "#{i} #{filename} old_hexdigest #{old_hexdigest} wasn't the same as new_hexdigest #{new_hexdigest}"
                            puts "  body was of length #{body.length}"
                            puts "  content type was: #{new_content_type}"
                            path = "/tmp/#{new_hexdigest}"
                            f = File.new path, "w"
                            f.write body
                            f.close
                            puts "  wrote body to #{path}"
                            attachments_with_different_hexdigest += 1
                        end
                    end
                end
            end

        end

        puts "total_attachments: #{total_attachments}"
        puts "attachments_with_different_hexdigest: #{attachments_with_different_hexdigest}"
        puts "files_with_different_numbers_of_attachments: #{files_with_different_numbers_of_attachments}"
        puts "no_tnef_attachments: #{no_tnef_attachments}"
        puts "no_parts_in_multipart: #{no_parts_in_multipart}"

    end

end
