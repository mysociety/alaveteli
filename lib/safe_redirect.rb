#
# Public: Sanitise a redirect parameter
require 'uri'

class SafeRedirect
  attr_reader :uri

  def initialize(redirect_parameter)
    @uri = URI.parse(redirect_parameter)
  end

  def path(opts = {})
    query = opts[:query]
    path = uri.path
    path = "/#{path}" unless path.empty? || path.start_with?('/')
    URI::Generic.build(path: path, query: query, fragment: uri.fragment).
      to_s
  end
end
