# Be sure to restart your server when you modify this file.
Rails.application.config.session_store :cookie_store, :key => '_wdtk_cookie_session'

# Insert a bit of middleware code to prevent uneeded cookie setting.
require "#{Rails.root}/lib/whatdotheyknow/strip_empty_sessions"
ActionController::Dispatcher.middleware.insert_before ActionController::Base.session_store, WhatDoTheyKnow::StripEmptySessions, :key => '_wdtk_cookie_session', :path => "/", :httponly => true

