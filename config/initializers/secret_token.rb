# -*- encoding : utf-8 -*-
# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# Just plopping an extra character on the secret_token so that any sessions on upgrading from
# Rails 2 to Rails 3 version of Alaveteli are invalidated.
# See http://blog.carbonfive.com/2011/03/19/rails-3-upgrade-tip-invalidate-session-cookies/

Alaveteli::Application.config.secret_token = "3" + AlaveteliConfiguration::cookie_store_session_secret
