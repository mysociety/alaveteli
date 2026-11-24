# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
# The `_key` regex skips non-secret ids such as dataset_key_set_id, so a
# post-redirect replay keeps them.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, /_key(?!(_set)?_id)/, :crypt, :salt,
  :certificate, :otp, :ssn, :cvv, :cvc
]

# Explicitly override above Rails defaults to allow logging of email parameters.
Rails.application.config.filter_parameters.delete(:email)
