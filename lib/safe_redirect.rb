# -*- encoding : utf-8 -*-
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
    URI::Generic.build(path: uri.path, query: query, fragment: uri.fragment).
      to_s
  end
end
