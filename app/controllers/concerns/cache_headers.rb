##
# Set Cache-Control headers for responses that can be cached when the user is
# not logged in.
#
module CacheHeaders
  extend ActiveSupport::Concern

  included do
    helper_method :anonymous_cache, :short_cache, :medium_cache, :long_cache
  end

  private

  def anonymous_cache(time)
    return if authenticated?

    headers['Cache-Control'] = "max-age=#{time}, public"
  end

  def short_cache
    anonymous_cache(60.seconds)
  end

  def medium_cache
    anonymous_cache(60.minutes)
  end

  def long_cache
    anonymous_cache(24.hours)
  end
end
