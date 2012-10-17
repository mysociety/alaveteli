# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

ActionController::Base.session = {
  :key => '_wdtk_cookie_session',
  :secret => Configuration::cookie_store_session_secret
}
ActionController::Base.session_store = :cookie_store

# Insert a bit of middleware code to prevent uneeded cookie setting.
require "#{Rails.root}/lib/whatdotheyknow/strip_empty_sessions"
ActionController::Dispatcher.middleware.insert_before ActionController::Base.session_store, WhatDoTheyKnow::StripEmptySessions, :key => '_wdtk_cookie_session', :path => "/", :httponly => true

