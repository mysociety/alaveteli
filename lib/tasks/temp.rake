namespace :temp do

    desc "Fix the history of requests where the described state doesn't match the latest status value
          used by search, by adding an edit event that will correct the latest status"
    task :fix_bad_request_states => :environment do
        dryrun = ENV['DRYRUN'] != '0'
        if dryrun
            puts "This is a dryrun"
        end

        InfoRequest.find_each() do |info_request|
            next if info_request.url_title == 'holding_pen'
            last_info_request_event = info_request.info_request_events[-1]
            if last_info_request_event.latest_status != info_request.described_state
                puts "#{info_request.id} #{info_request.url_title} #{last_info_request_event.latest_status} #{info_request.described_state}"
                params = { :script => 'rake temp:fix_bad_request_states',
                           :user_id => nil,
                           :old_described_state => info_request.described_state,
                           :described_state => info_request.described_state
                          }
                if ! dryrun
                    info_request.info_request_events.create!(:last_described_at => last_info_request_event.described_at + 1.second,
                                                             :event_type => 'status_update',
                                                             :described_state => info_request.described_state,
                                                             :calculated_state => info_request.described_state,
                                                             :params => params)
                    info_request.info_request_events.each{ |event| event.xapian_mark_needs_index }
                end
            end

        end
    end

    def disable_duplicate_account(user, count, dryrun)
        dupe_email = "duplicateemail#{count}@example.com"
        puts "Updating #{user.email} to #{dupe_email} for user #{user.id}"
        user.email = dupe_email
        user.save! unless dryrun
    end

    desc "Re-extract any missing cached attachments"
    task :reextract_missing_attachments, [:commit] => :environment do |t, args|
        dry_run = args.commit.nil? || args.commit.empty?
        total_messages = 0
        messages_to_reparse = 0
        IncomingMessage.find_each :include => :foi_attachments do |im|
            begin
                reparse = im.foi_attachments.any? { |fa| ! File.exists? fa.filepath }
                total_messages += 1
                messages_to_reparse += 1 if reparse
                if total_messages % 1000 == 0
                    puts "Considered #{total_messages} received emails."
                end
                unless dry_run
                    im.parse_raw_email! true if reparse
                    sleep 2
                end
            rescue StandardError => e
                puts "There was a #{e.class} exception reparsing IncomingMessage with ID #{im.id}"
                puts e.backtrace
                puts e.message
            end
        end
        message = dry_run ? "Would reparse" : "Reparsed"
        message += " #{messages_to_reparse} out of #{total_messages} received emails."
        puts message
    end

    desc 'Cleanup accounts with a space in the email address'
    task :clean_up_emails_with_spaces => :environment do
        dryrun = ENV['DRYRUN'] == '0' ? false : true
        if dryrun
            puts "This is a dryrun"
        end
        count = 0
        User.find_each do |user|
            if / /.match(user.email)

                email_without_spaces = user.email.gsub(' ', '')
                existing = User.find_user_by_email(email_without_spaces)
                # Another account exists with the canonical address
                if existing
                    if user.info_requests.count == 0 and user.comments.count == 0 and user.track_things.count == 0
                        count += 1
                        disable_duplicate_account(user, count, dryrun)
                    elsif existing.info_requests.count == 0 and existing.comments.count == 0 and existing.track_things.count == 0
                        count += 1
                        disable_duplicate_account(existing, count, dryrun)
                        user.email = email_without_spaces
                        puts "Updating #{user.email} to #{email_without_spaces} for user #{user.id}"
                        user.save! unless dryrun
                    else
                        user.info_requests.each do |info_request|
                            info_request.user = existing
                            info_request.save! unless dryrun
                            puts "Moved request #{info_request.id} from user #{user.id} to #{existing.id}"
                        end

                        user.comments.each do |comment|
                            comment.user = existing
                            comment.save! unless dryrun
                            puts "Moved comment #{comment.id} from user #{user.id} to #{existing.id}"
                        end

                        user.track_things.each do |track_thing|
                            track_thing.tracking_user = existing
                            track_thing.save! unless dryrun
                            puts "Moved track thing #{track_thing.id} from user #{user.id} to #{existing.id}"
                        end

                        TrackThingsSentEmail.find_each(:conditions => ['user_id = ?', user]) do |sent_email|
                            sent_email.user = existing
                            sent_email.save! unless dryrun
                            puts "Moved track thing sent email #{sent_email.id} from user #{user.id} to #{existing.id}"

                        end

                        user.censor_rules.each do |censor_rule|
                            censor_rule.user = existing
                            censor_rule.save! unless dryrun
                            puts "Moved censor rule #{censor_rule.id} from user #{user.id} to #{existing.id}"
                        end

                        user.user_info_request_sent_alerts.each do |sent_alert|
                            sent_alert.user = existing
                            sent_alert.save! unless dryrun
                            puts "Moved sent alert #{sent_alert.id} from user #{user.id} to #{existing.id}"
                        end

                        count += 1
                        disable_duplicate_account(user, count, dryrun)
                    end
                else
                    puts "Updating #{user.email} to #{email_without_spaces} for user #{user.id}"
                    user.email = email_without_spaces
                    user.save! unless dryrun
                end
            end
        end
    end

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
