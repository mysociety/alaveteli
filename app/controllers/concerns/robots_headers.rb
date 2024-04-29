##
# Set robots noindex headers.
#
module RobotsHeaders
  extend ActiveSupport::Concern

  private

  def set_no_crawl_headers
    headers['X-Robots-Tag'] = 'noindex'
  end
end
