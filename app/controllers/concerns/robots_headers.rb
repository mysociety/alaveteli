##
# Set robots noindex headers.
#
module RobotsHeaders
  extend ActiveSupport::Concern

  included do
    before_action :set_no_crawl_headers, if: -> { params[:page].to_i > 1 }
  end

  private

  def set_no_crawl_headers
    @no_crawl = true
    headers['X-Robots-Tag'] = 'noindex, nofollow'
  end
end
