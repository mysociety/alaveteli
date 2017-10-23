# -*- encoding : utf-8 -*-
# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'action_mailer/version'
class ApplicationMailer < ActionMailer::Base
  # Include all the functions views get, as emails call similar things.
  helper :application
  include MailerHelper
  include AlaveteliFeatures::Helpers

  # This really should be the default - otherwise you lose any information
  # about the errors, and have to do error checking on return codes.
  self.raise_delivery_errors = true

  def blackhole_email
    AlaveteliConfiguration::blackhole_prefix+"@"+AlaveteliConfiguration::incoming_email_domain
  end

  def mail_user(user, subject, opts = {})
    default_opts = {
      :from => contact_for_user(user),
      :to => user.name_and_email,
      :subject => subject,
    }
    default_opts.merge!(opts)
    mail(default_opts)
  end

  def contact_for_user(user = nil)
    if feature_enabled?(:alaveteli_pro) and user and user.is_pro?
      pro_contact_from_name_and_email
    else
      contact_from_name_and_email
    end
  end

  # Set headers that mark an email as being auto-generated and suppress out of
  # office responses to them
  def set_auto_generated_headers(opts = {})
    headers({
      'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
      'X-Auto-Response-Suppress' => 'OOF',
    })
  end

  # Set Return-Path and Reply-To headers
  #
  # Note:
  # - We set Return-Path, so you should always set Reply-To to be different
  #   from From, since some email clients seem to erroneously use the envelope
  #   from when they shouldn't, and this might help. (Have had mysterious
  #   cases of a reply coming in duplicate from a public body to both From and
  #   envelope from).
  # - Return-Path is a special address we control so that SPF checks are done
  #   on it.
  # - When sending emails from one user to another, do not set envelope from
  #   address to the from_user, so they can't get someone's email addresses
  #   from transitory bounce messages.
  def set_reply_to_headers(user = nil, opts = {})
    default_opts = {
      'Return-Path' => blackhole_email,
      'Reply-To' => contact_for_user(user)
    }
    default_opts.merge!(opts)
    headers(default_opts)
  end

  # URL generating functions are needed by all controllers (for redirects),
  # views (for links) and mailers (for use in emails), so include them into
  # all of all.
  include LinkToHelper

  # Site-wide access to configuration settings
  include ConfigHelper

end
