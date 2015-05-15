# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: mail_server_logs
#
#  id                      :integer          not null, primary key
#  mail_server_log_done_id :integer
#  info_request_id         :integer
#  order                   :integer          not null
#  line                    :text             not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

# We load log file lines for requests in here, for display in the admin interface.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class MailServerLog < ActiveRecord::Base
    belongs_to :info_request
    belongs_to :mail_server_log_done

    # Load in exim or postfix log file from disk, or update if we already have it
    # Assumes files are named with date, rather than cyclically.
    # Doesn't do anything if file hasn't been modified since it was last loaded.
    # Note: If you do use rotated log files (rather than files named by date), at some
    # point old loaded log lines will get deleted in the database.
    def MailServerLog.load_file(file_name)
        is_gz = file_name.include?(".gz")
        file_name_db = is_gz ? file_name.gsub(".gz", "") : file_name

        modified = File.stat(file_name).mtime
        raise "MailServerLog.load_file: file not found " + file_name if modified.nil?

        ActiveRecord::Base.transaction do
            # see if we already have it
            done = MailServerLogDone.find_by_filename(file_name_db)
            if done
                if modified.utc == done.last_stat.utc
                    # already have that, nothing to do
                    return
                else
                    MailServerLog.delete_all "mail_server_log_done_id = " + done.id.to_s
                end
            else
                done = MailServerLogDone.new(:filename => file_name_db)
            end
            done.last_stat = modified
            # update done structure so we know when we last read this file
            done.save!

            f = is_gz ? Zlib::GzipReader.open(file_name) : File.open(file_name, 'r')
            case(AlaveteliConfiguration::mta_log_type.to_sym)
            when :exim
                load_exim_log_data(f, done)
            when :postfix
                load_postfix_log_data(f, done)
            else
                raise "Unexpected MTA type: #{type}"
            end
        end
    end

    # Scan the file
    def MailServerLog.load_exim_log_data(f, done)
        order = 0
        f.each do |line|
            order = order + 1
            emails = email_addresses_on_line(line)
            for email in emails
                info_request = InfoRequest.find_by_incoming_email(email)
                if info_request
                    info_request.mail_server_logs.create!(:line => line, :order => order, :mail_server_log_done => done)
                else
                    puts "Warning: Could not find request with email #{email}"
                end
            end
        end
    end

    def MailServerLog.load_postfix_log_data(f, done)
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
                        info_request.mail_server_logs.create!(:line => line, :order => order, :mail_server_log_done => done)
                    else
                        puts "Warning: Could not find request with email #{email}"
                    end                    
                end
            end
        end
    end

    def MailServerLog.scan_for_postfix_queue_ids(f)
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
    def MailServerLog.extract_postfix_queue_id_from_syslog_line(line)
        # Assume the log file was written using syslog and parse accordingly
        m = SyslogProtocol.parse("<13>" + line).content.match(/^\S+: (\S+):/)
        m[1] if m
    end

    # We also check the email prefix so that we could, for instance, separately handle a staging and production
    # instance running on the same server with different email prefixes.
    def MailServerLog.email_addresses_on_line(line)
        prefix = Regexp::quote(AlaveteliConfiguration::incoming_email_prefix)
        domain = Regexp::quote(AlaveteliConfiguration::incoming_email_domain)
        line.scan(/#{prefix}request-[^\s]+@#{domain}/).sort.uniq
    end

    def MailServerLog.request_sent?(ir)
        case(AlaveteliConfiguration::mta_log_type.to_sym)
        when :exim
            request_exim_sent?(ir)
        when :postfix
            request_postfix_sent?(ir)
        else
            raise "Unexpected MTA type: #{type}"
        end
    end

    # Look at the log for a request and check that an email was delivered
    def MailServerLog.request_exim_sent?(ir)
        # Look for line showing request was sent
        found = false
        ir.mail_server_logs.each do |mail_server_log|
            test_outgoing = " <= " + ir.incoming_email + " "
            if mail_server_log.line.include?(test_outgoing)
                # Check the from value is the same (it always will be, but may as well
                # be sure we are parsing the exim line right)
                envelope_from = " from <" + ir.incoming_email + "> "
                if !mail_server_log.line.include?(envelope_from)
                    $stderr.puts("unexpected parsing of exim line: [#{mail_server_log.line.chomp}]")
                else
                    found = true
                end
            end
        end
        found
    end

    def MailServerLog.request_postfix_sent?(ir)
        # dsn=2.0.0 is the magic word that says that postfix delivered the email
        # See http://tools.ietf.org/html/rfc3464
        ir.mail_server_logs.any? { |l| l.line.include?("dsn=2.0.0") }
    end

    # Check that the last day of requests has been sent in Exim or Postfix and we got the
    # lines. Writes any errors to STDERR. This check is really mainly to
    # check the envelope from is the request address, as Ruby is quite
    # flaky with regard to that, and it is important for anti-spam reasons.
    # TODO: does this really check that, as the log just wouldn't pick
    # up at all if the requests weren't sent that way as there would be
    # no request- email in it?
    #
    # NB: There can be several emails involved in a request. This just checks that
    # at least one of them has been succesfully sent.
    #
    def MailServerLog.check_recent_requests_have_been_sent
        # Get all requests sent for from 2 to 10 days ago. The 2 day gap is
        # because we load mail server log lines via cron at best an hour after they
        # are made)
        irs = InfoRequest.find(:all, :conditions => [ "created_at < ? and created_at > ? and user_id is not null", Time.now() - 2.day, Time.now() - 10.days ] )

        # Go through each request and check it
        ok = true
        irs.each do |ir|
            unless request_sent?(ir)
                # It's very important the envelope from is set for avoiding spam filter reasons - this
                # effectively acts as a check for that.
                $stderr.puts("failed to find request sending in MTA logs for request id " + ir.id.to_s + " " + ir.url_title + " (check envelope from is being set to request address in Ruby, and load-mail-server-logs crontab is working)") # *** don't comment out this STDERR line, it is the point of the function!
                ok = false
            end
        end
        ok
    end

end



