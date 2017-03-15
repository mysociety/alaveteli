# -*- encoding : utf-8 -*-
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.

# Example Rails 4 secret_key_base option
# Alaveteli::Application.config.secret_key_base = 'f72449ebf68e2277718f5dd2635cbca6a62d80f5edbc6ebc0fb2462b6ccf773e09d0f257ca7ebb04cea812528da3b6a248acf350841e2f95e4d6f63deb054394'

# Just plopping an extra character on the secret_token so that any sessions on upgrading from
# Rails 2 to Rails 3 version of Alaveteli are invalidated.
# See http://blog.carbonfive.com/2011/03/19/rails-3-upgrade-tip-invalidate-session-cookies/
Alaveteli::Application.config.secret_token = "3" + AlaveteliConfiguration::cookie_store_session_secret
