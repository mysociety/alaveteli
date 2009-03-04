# == Schema Information
# Schema version: 72
#
# Table name: exim_logs
#
#  id               :integer         not null, primary key
#  exim_log_done_id :integer         
#  info_request_id  :integer         
#  order            :integer         not null
#  line             :text            not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

# models/exim_log.rb:
# We load log file lines for requests in here, for display in the admin interface.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: exim_log.rb,v 1.6 2009-03-04 11:26:35 tony Exp $

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
                        #STDERR.puts "adding log for " + info_request.url_title + " from " + file_name + " line " + line
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

    # Check that the last day of requests has been sent in Exim and we got the
    # lines. Writes any errors to STDERR. This check is really mainly to
    # check the envelope from is the request address, as Ruby is quite
    # flaky with regard to that, and it is important for anti-spam reasons.
    def EximLog.check_recent_requests_have_been_sent
        # Get all requests sent for a period of 24 hours, ending a day ago.
        # (the gap is because we load exim log lines via cron at best an hour
        # after they are made)
        irs = InfoRequest.find(:all, :conditions => [ "created_at < ? and created_at > ?", Time.now() - 1.day, Time.now() - 2.days ] )

        # Go through each request and check it
        for ir in irs
            # Look for line showing request was sent
            found = false
            for exim_log in ir.exim_logs
                test_outgoing = " <= " + ir.incoming_email + " "
                if exim_log.line.include?(test_outgoing)
                    # Check the from value is the same (it always will be, but may as well
                    # be sure we are parsing the exim line right)
                    envelope_from = " from <" + ir.incoming_email + "> "
                    if !exim_log.line.include?(envelope_from)
                        raise "unexpected parsing of exim line"
                    end

                    STDERR.puts "check_recent_requests_have_been_sent test: " + exim_log.line # debugging
                    found = true
                end
            end
            if !found
                # It's very important the envelope from is set for avoiding spam filter reasons - this
                # effectively acts as a check for that.
                STDERR.puts("failed to find request sending Exim line for request id " + ir.id.to_s + " " + ir.url_title + " (check envelope from is being set to request address in Ruby, and load-exim-logs crontab is working)") # *** don't comment out this STDERR line, it is the point of the function!
            end
        end
    end
    
end



