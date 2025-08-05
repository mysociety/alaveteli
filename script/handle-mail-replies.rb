#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

# Handle email responses sent to us.
#
# This script is invoked as a pipe command, i.e. with the raw email message on stdin.
# - If a message is identified as a permanent bounce, the user is marked as having a
#   bounced address, and will not be sent any more messages.
# - If a message is identified as an out-of-office autoreply, it is discarded.
# - Any other messages are forwarded to config.get("FORWARD_NONBOUNCE_RESPONSES_TO")
#   or config.get("FORWARD_PRO_NONBOUNCE_RESPONSES_TO") depending on whether
#   they were sent from the normal contact address or the pro one initially.

# We want to avoid loading rails unless we need it, so we start by just loading the
# config file ourselves.
require 'active_support/all'

$alaveteli_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

$LOAD_PATH.push(File.join($alaveteli_dir, 'commonlib', 'rblib'))
load 'config.rb'
MySociety::Config.set_file(File.join($alaveteli_dir, 'config', 'general'), true)
MySociety::Config.load_default

$LOAD_PATH.push(File.join($alaveteli_dir, 'lib'))
load 'configuration.rb'

$LOAD_PATH.push(File.join($alaveteli_dir, 'app', 'helpers'))
require 'config_helper'

$LOAD_PATH.push(File.join($alaveteli_dir, 'lib', 'mail_handler'))
require 'mail_handler'
require 'reply_handler'

# the default encoding for IO is utf-8, and we use utf-8 internally
Encoding.default_external = Encoding.default_internal = Encoding::UTF_8

def main(in_test_mode)
  Dir.chdir($alaveteli_dir) do
    raw_message = $stdin.read
    begin
      message = MailHandler.mail_from_raw_email(raw_message)
    rescue
      # Error parsing message. Just pass it on, to be on the safe side.
      MailHandler::ReplyHandler.forward_on(raw_message) unless in_test_mode
      return 0
    end

    pfas = MailHandler::ReplyHandler.permanently_failed_addresses(message)
    if !pfas.empty?
      if in_test_mode
        puts pfas
      else
        pfas.each do |pfa|
          MailHandler::ReplyHandler.record_bounce(pfa, raw_message)
        end
      end
      return 1
    end

    content_type = MailHandler.get_content_type(message)
    # If we are still here, there are no permanent failures,
    # so if the message is a multipart/report then it must be
    # reporting a temporary failure. In this case we discard it
    if content_type == "multipart/report"
      return 1
    end

    # Another style of temporary failure message
    subject = MailHandler.get_header_string("Subject", message)
    if content_type == "multipart/mixed" && subject == "Delivery Status Notification (Delay)"
      return 1
    end

    # Discard out-of-office messages
    if MailHandler::ReplyHandler.is_oof?(message)
      return 2 # Use a different return code, to distinguish OOFs from bounces
    end

    # Otherwise forward the message on
    MailHandler::ReplyHandler.forward_on(raw_message, message) unless in_test_mode
    return 0
  end
end

in_test_mode = (ARGV[0] == "--test")
status = main(in_test_mode)
exit(status) if in_test_mode
