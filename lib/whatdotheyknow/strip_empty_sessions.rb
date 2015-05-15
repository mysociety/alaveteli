# -*- encoding : utf-8 -*-
module WhatDoTheyKnow

  class StripEmptySessions
    ENV_SESSION_KEY = "rack.session".freeze
    HTTP_SET_COOKIE = "Set-Cookie".freeze
    STRIPPABLE_KEYS = ['session_id', '_csrf_token', 'locale']

    def initialize(app, options = {})
      @app = app
      @options = options
    end

    def call(env)
      status, headers, body = @app.call(env)
      session_data = env[ENV_SESSION_KEY]
      set_cookie = headers[HTTP_SET_COOKIE]
      if session_data
        if (session_data.keys - STRIPPABLE_KEYS).empty?
          if set_cookie.is_a? Array
            set_cookie.reject! {|c| c.match(/^\n?#{@options[:key]}=/)}
          elsif set_cookie.is_a? String
            headers[HTTP_SET_COOKIE].gsub!( /(^|\n)#{@options[:key]}=.*?(\n|$)/, "" )
          end
        end
      end
      [status, headers, body]
    end
  end
end
