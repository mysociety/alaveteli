# -*- encoding : utf-8 -*-
# Rack Middleware to prevent setting a session cookie when there's no data to
# store in it.
class StripEmptySessions
  ENV_SESSION_KEY = 'rack.session'.freeze
  HTTP_SET_COOKIE = 'Set-Cookie'.freeze
  STRIPPABLE_KEYS = %w(session_id _csrf_token locale)

  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
    status, headers, body = @app.call(env)

    session_data = env[ENV_SESSION_KEY]

    if session_data && (session_data.keys - STRIPPABLE_KEYS).empty?
      headers[HTTP_SET_COOKIE]&.gsub!(/(^|\n)#{@options[:key]}=.*?(\n|$)/, '')
    end

    [status, headers, body]
  end
end
