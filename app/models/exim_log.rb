# models/exim_log.rb:
# We load log file lines for requests in here, for display in the admin interface.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: exim_log.rb,v 1.2 2009-01-27 17:50:14 francis Exp $

class EximLog < ActiveRecord::Base
    belongs_to :info_request
    belongs_to :exim_log_done

    # Load in exim log file from disk, or update if we already have it
    # Assumes files are named with date, rather than cyclically.
    # Doesn't do anything if file hasn't been modified since it was last loaded.
    def EximLog.load_file(file_name)
        modified = File::stat(file_name).mtime
        raise "EximLog.load_file: file not found " + file_name if modified.nil?

        ActiveRecord::Base.transaction do
            # see if we already have it
            done = EximLogDone.find_by_filename(file_name)  
            if !done.nil?
                if modified.utc == done.last_stat.utc
                    # already have that, nothing to do
                    return
                end
                EximLog.delete_all "exim_log_done_id = " + done.id.to_s
            end
            if !done
                done = EximLogDone.new
                done.filename = file_name
            end
            done.last_stat = modified

            # scan the file
            f = File.open(file_name, 'r')
            order = 0
            for line in f
                order = order + 1
                email_domain = MySociety::Config.get("INCOMING_EMAIL_DOMAIN", "localhost")
                emails = line.scan(/request-[^\s]+@#{email_domain}/).sort.uniq
                for email in emails
                    info_request = InfoRequest.find_by_incoming_email(email)
                    if !info_request.nil?
                        STDERR.puts "adding log for " + info_request.url_title + " from " + file_name + " line " + line
                        exim_log = EximLog.new
                        exim_log.info_request = info_request
                        exim_log.exim_log_done = done
                        exim_log.line = line
                        exim_log.order = order
                        exim_log.save!
                    end
                end
            end

            # update done structure so we know when we last read this file
            done.save!
        end
    end
end



