##
# Class responsible for loading external blog content
#
# Requires `BLOG_FEED` to be configured in config/general.yml
#
# Currently WordPress is the only "officially supported" external blog feed,
# but other feeds may work if they use the same data format.
#
class Blog
  include ConfigHelper

  def self.enabled?
    AlaveteliConfiguration.blog_feed.present?
  end

  def posts
    return [] if content.empty?

    data = XmlSimple.xml_in(content)
    channel = data['channel'][0]
    channel.fetch('item') { [] }
  end

  def feeds
    [{ url: feed_url, title: "#{site_name} blog" }]
  end

  def feed_url
    uri = URI(AlaveteliConfiguration.blog_feed)
    uri.query = URI.decode_www_form(uri.query || '').to_h.merge(
      lang: AlaveteliLocalization.html_lang.to_s
    ).to_param
    uri.to_s
  end

  private

  def content
    @content ||= quietly_try_to_open(feed_url, timeout)
  end

  def timeout
    AlaveteliConfiguration.blog_timeout.presence || 60
  end
end
