# == Schema Information
# Schema version: 114
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
# $Id: exim_log.rb,v 1.14 2009-09-17 21:10:05 francis Exp $

class EximLog < ActiveRecord::Base
    belongs_to :info_request
    belongs_to :exim_log_done

    # Load in exim log file from disk, or update if we already have it
    # Assumes files are named with date, rather than cyclically.
    # Doesn't do anything if file hasn't been modified since it was last loaded.
    # Note: If you do use rotated log files (rather than files named by date), at some
    # point old loaded log lines will get deleted in the database.
    def EximLog.load_file(file_name)
        is_gz = file_name.include?(".gz")
        file_name_db = is_gz ? file_name.gsub(".gz", "") : file_name

        modified = File.stat(file_name).mtime
        raise "EximLog.load_file: file not found " + file_name if modified.nil?

        ActiveRecord::Base.transaction do
            # see if we already have it
            done = EximLogDone.find_by_filename(file_name_db)
            if done
                if modified.utc == done.last_stat.utc
                    # already have that, nothing to do
                    return
                else
                    EximLog.delete_all "exim_log_done_id = " + done.id.to_s
                end
            else
                done = EximLogDone.new(:filename => file_name_db)
            end
            done.last_stat = modified
            # update done structure so we know when we last read this file
            done.save!

            f = is_gz ? Zlib::GzipReader.open(file_name) : File.open(file_name, 'r')
            type = detect_mta_log_type(f)
            case(type)
            when :exim
                load_exim_log_data(f, done)
            when :postfix
                load_postfix_log_data(f, done)
            else
                raise "Unexpected MTA type: #{type}"
            end
        end
    end

    # Unbelievably dumb heuristic for detecting whether this is an exim or a postfix log
    def EximLog.detect_mta_log_type(f)
        r = (f.readline =~ /postfix/) ? :postfix : :exim
        f.rewind
        r
    end

    # Scan the file
    def EximLog.load_exim_log_data(f, done)
        order = 0
        f.each do |line|
            order = order + 1
            emails = email_addresses_on_line(line)
            for email in emails
                info_request = InfoRequest.find_by_incoming_email(email)
                if info_request
                    info_request.exim_logs.create!(:line => line, :order => order, :exim_log_done => done)
                else
                    puts "Warning: Could not find request with email #{email}"
                end
            end
        end
    end

    def EximLog.load_postfix_log_data(f, done)
        order = 0
        emails = scan_for_postfix_queue_ids(f)
        # Go back to the beginning of the file
        f.rewind
        f.each do |line|
            order = order + 1
            queue_id = extract_postfix_queue_id_from_syslog_line(line)
            if emails.has_key?(queue_id)
                emails[queue_id].each do |email|
                    info_request = InfoRequest.find_by_incoming_email(email)
                    if info_request
                        info_request.exim_logs.create!(:line => line, :order => order, :exim_log_done => done)
                    else
                        puts "Warning: Could not find request with email #{email}"
                    end                    
                end
            end
        end
    end

    def EximLog.scan_for_postfix_queue_ids(f)
        result = {}
        f.each do |line|
            emails = email_addresses_on_line(line)
            queue_id = extract_postfix_queue_id_from_syslog_line(line)
            result[queue_id] = [] unless result.has_key?(queue_id)
            result[queue_id] = (result[queue_id] + emails).uniq
        end
        result
    end

    # Retuns nil if there is no queue id
    def EximLog.extract_postfix_queue_id_from_syslog_line(line)
        # Assume the log file was written using syslog and parse accordingly
        m = SyslogProtocol.parse("<13>" + line).content.match(/^\S+: (\S+):/)
        m[1] if m
    end

    def EximLog.email_addresses_on_line(line)
        line.scan(/request-[^\s]+@#{Configuration::incoming_email_domain}/).sort.uniq
    end

    # Check that the last day of requests has been sent in Exim and we got the
    # lines. Writes any errors to STDERR. This check is really mainly to
    # check the envelope from is the request address, as Ruby is quite
    # flaky with regard to that, and it is important for anti-spam reasons.
    # XXX does this really check that, as the exim log just wouldn't pick
    # up at all if the requests weren't sent that way as there would be
    # no request- email in it?
    def EximLog.check_recent_requests_have_been_sent
        # Get all requests sent for from 2 to 10 days ago. The 2 day gap is
        # because we load exim log lines via cron at best an hour after they
        # are made)
        irs = InfoRequest.find(:all, :conditions => [ "created_at < ? and created_at > ? and user_id is not null", Time.now() - 2.day, Time.now() - 10.days ] )

        # Go through each request and check it
        ok = true
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
                        $stderr.puts("unexpected parsing of exim line: [#{exim_log.line.chomp}]")
                    else
                        found = true
                    end
                end
            end
            if !found
                # It's very important the envelope from is set for avoiding spam filter reasons - this
                # effectively acts as a check for that.
                $stderr.puts("failed to find request sending Exim line for request id " + ir.id.to_s + " " + ir.url_title + " (check envelope from is being set to request address in Ruby, and load-exim-logs crontab is working)") # *** don't comment out this STDERR line, it is the point of the function!
                ok = false
            end
        end

        return ok
    end

end



