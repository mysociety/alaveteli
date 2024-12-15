# == Schema Information
# Schema version: 20210114161442
#
# Table name: post_redirects
#
#  id                 :integer          not null, primary key
#  token              :text             not null
#  uri                :text             not null
#  post_params_yaml   :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  email_token        :text             not null
#  reason_params_yaml :text
#  user_id            :integer
#  circumstance       :text             default("normal"), not null
#

# models/post_redirect.rb:
# Saves an HTTP request, so it can be redirected to later.  For example, after
# registering / logging in. This can save POST requests, if post_params_yaml
# is not null.
#
# See check_in_post_redirect in controllers/application.rb for the hack that
# fakes the redirect to include POST parameters in request later.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'digest'
require 'openssl' # for random bytes function

class PostRedirect < ApplicationRecord
  CIRCUMSTANCES = %w(change_password change_email normal)

  # Optional, does a login confirm before redirect for use in email links.
  belongs_to :user,
             inverse_of: :post_redirects,
             optional: true

  validates :circumstance, inclusion: CIRCUMSTANCES

  after_initialize :generate_token
  after_initialize :generate_email_token

  def self.verifier
    Rails.application.message_verifier(to_s)
  end

  def self.generate_verifiable_token(user:, circumstance:)
    verifier.generate(
      { user_id: user.id, login_token: user.login_token },
      purpose: circumstance
    )
  end

  # Makes a random token, suitable for using in URLs e.g confirmation
  # messages.
  def self.generate_random_token
    MySociety::Util.generate_token
  end

  # Called from cron job delete-old-things
  def self.delete_old_post_redirects
    PostRedirect.where("updated_at < (now() - interval '2 months')").delete_all
  end

  # We store YAML version of POST parameters in the database
  def post_params=(params)
    self.post_params_yaml = params.to_yaml
  end

  def post_params
    return {} if post_params_yaml.nil?

    if RUBY_VERSION < "3.1"
      YAML.load(post_params_yaml)
    else
      YAML.load(
        post_params_yaml,
        permitted_classes: [
          ActionController::Parameters,
          ActiveSupport::HashWithIndifferentAccess,
          Symbol
        ]
      )
    end
  end

  # We store YAML version of textual "reason for redirect" parameters
  def reason_params=(reason_params)
    self.reason_params_yaml = reason_params.to_yaml
  end

  def reason_params
    param_hash = YAML.load(reason_params_yaml)
    param_hash.each do |key, value|
      if value.respond_to?(:force_encoding)
        param_hash[key] = value.force_encoding('UTF-8')
      end
    end
    param_hash
  end

  # Extract just local path part, without domain or #
  def local_part_uri
    uri.match(/^http:\/\/.+?(\/[^#]+)/)
    $1
  end

  def email_token_valid?
    return true unless PostRedirect.verifier.valid_message?(email_token)

    data = PostRedirect.verifier.verify(email_token, purpose: circumstance)
    user.id == data[:user_id] && user.login_token == data[:login_token]
  end

  private

  # The token is used to return you to what you are doing after the login
  # form.
  def generate_token
    self.token = PostRedirect.generate_random_token unless token
  end

  # There is a separate token to use in the URL if we send a confirmation
  # email.
  def generate_email_token
    if !user || circumstance == 'normal'
      self.email_token ||= PostRedirect.generate_random_token
    end

    self.email_token ||= PostRedirect.generate_verifiable_token(
      user: user, circumstance: circumstance
    )
  end
end
