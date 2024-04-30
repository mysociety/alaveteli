##
# Set robots noindex headers.
#
module RobotsHeaders
  extend ActiveSupport::Concern

  private

  def set_no_crawl_headers
    @no_crawl = true
    headers['X-Robots-Tag'] = 'noindex, nofollow'
  end
end
