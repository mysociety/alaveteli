##
# Check if Rack will raise RangeError when parsing query params.
#
# If `Rack::Utils.param_depth_limit` is too low or if a malformed request is
# received then this can happen.
#
class DeeplyNestedParams
  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
    Rack::Utils.parse_query(env['QUERY_STRING'])
    @app.call(env)
  rescue RangeError
    [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
  end
end
