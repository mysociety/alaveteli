# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'action_mailer/version'
class ApplicationMailer < ActionMailer::Base
  # Include all the functions views get, as emails call similar things.
  helper :application
  layout 'default_mailer'
  include MailerHelper
  include AlaveteliFeatures::Helpers

  # URL generating functions are needed by all controllers (for redirects),
  # views (for links) and mailers (for use in emails), so include them into
  # all of all.
  include LinkToHelper

  # Site-wide access to configuration settings
  include ConfigHelper

  # This really should be the default - otherwise you lose any information
  # about the errors, and have to do error checking on return codes.
  self.raise_delivery_errors = true

  # The subject: arg must be a proc, it is localized with the user's locale.
  def mail_user(user, subject:, **opts)
    if user.is_a?(User)
      locale = user.locale
      opts[:to] = user.name_and_email
    else
      opts[:to] = user
    end

    if opts[:from].is_a?(User)
      set_reply_to_headers('Reply-To' => opts[:from].name_and_email)
      opts[:from] = MailHandler.address_from_name_and_email(
        opts[:from].name, blackhole_email
      )
    else
      set_reply_to_headers
      opts[:from] ||= blackhole_email
    end

    set_auto_generated_headers

    default_opts = {
      subject: AlaveteliLocalization.with_locale(locale) { subject.call }
    }
    default_opts.merge!(opts)
    mail(default_opts)
  end

  def contact_for_user(user = nil)
    if feature_enabled?(:alaveteli_pro) && user && user.is_pro?
      pro_contact_from_name_and_email
    else
      contact_from_name_and_email
    end
  end

  # Set headers that mark an email as being auto-generated and suppress out of
  # office responses to them
  def set_auto_generated_headers(_opts = {})
    headers(
      'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
      'X-Auto-Response-Suppress' => 'OOF'
    )
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
  def set_reply_to_headers(opts = {})
    default_opts = {
      'Return-Path' => blackhole_email
    }
    default_opts.merge!(opts)
    headers(default_opts)
  end

  def set_footer_template
    @footer_template = nil
  end
end
