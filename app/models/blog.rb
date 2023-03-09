##
# Class responsible for loading external blog content
#
# Requires `BLOG_FEED` to be configured in config/general.yml
#
# Currently WordPress is the only "officially supported" external blog feed,
# but other feeds may work if they use the same data format.
#
class Blog
  def self.enabled?
    AlaveteliConfiguration.blog_feed.present?
  end
end
