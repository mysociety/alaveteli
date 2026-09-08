##
# Builds the XML sitemap files which tell search engines what to index.
#
# Alaveteli caps its own request listings at RequestController::MAX_RESULTS and
# marks every page after the first as `noindex`, so a crawler which only follows
# links reaches a small fraction of the requests a site holds. The sitemap is
# what makes the rest of the archive discoverable.
#
# Files are written to a directory which survives deploys and are served by
# SitemapsController rather than from public/, so that ENABLE_SITEMAP can switch
# them off.
#
class Sitemap
  include Rails.application.routes.url_helpers

  # Indexable pages which the queries below don't cover.
  #
  # Anything robots.txt disallows is deliberately absent: naming a blocked URL
  # in a sitemap is a contradiction which search engines report as an error.
  STATIC_ROUTES = %i[
    frontpage_path
    requests_path
    request_list_path
    list_public_bodies_path
    citations_path
    help_about_path
    help_requesting_path
    help_privacy_path
    help_officers_path
    help_unhappy_path
    help_credits_path
    help_api_path
  ].freeze

  class << self
    def enabled?
      AlaveteliConfiguration.enable_sitemap
    end

    def directory
      Rails.root.join('cache', 'sitemaps')
    end

    # The index is left uncompressed so that it can live at the conventional
    # /sitemap.xml. The sitemaps it points at are gzipped.
    def path_for(number = nil)
      filename = number.present? ? "sitemap#{number}.xml.gz" : 'sitemap.xml'
      directory.join(filename)
    end

    def generate!
      new.generate!
    end

    def host
      protocol = AlaveteliConfiguration.force_ssl ? 'https' : 'http'
      "#{protocol}://#{AlaveteliConfiguration.domain}"
    end

    # The absolute URL robots.txt advertises. The sitemap protocol requires an
    # absolute URL here, which is why it comes from the configured domain
    # rather than being hardcoded.
    def url
      "#{host}#{Rails.application.routes.url_helpers.sitemap_path}"
    end
  end

  # Writes a complete set of sitemaps, then swaps them into place.
  #
  # Generating in a scratch directory means a crawler never reads an index which
  # points at sitemaps that haven't been written yet.
  def generate!
    scratch = sibling_directory('new')
    FileUtils.rm_rf(scratch)
    FileUtils.mkdir_p(scratch)

    build_into(scratch)
    swap_into_place(scratch)
  end

  def each_url
    STATIC_ROUTES.each { |route| yield public_send(route) }

    PublicBody.visible.includes(:translations).find_each do |public_body|
      next if public_body.url_name.blank?

      yield show_public_body_path(url_name: public_body.url_name)
    end

    # Only the columns needed to build a URL are selected. Loading whole rows
    # here means streaming every request's title and description through memory.
    #
    # last_event_time is preferred over updated_at because it moves when the
    # page changes rather than on bookkeeping writes, but it is only set once a
    # request has logged an event, so fall back rather than emit no date.
    InfoRequest.is_searchable.
      select(:id, :url_title, :last_event_time, :updated_at).
      find_each do |info_request|
        lastmod = info_request.last_event_time || info_request.updated_at
        yield show_request_path(info_request.url_title), { lastmod: lastmod }
      end
  end

  private

  def build_into(output_directory)
    urls = self

    SitemapGenerator::Sitemap.tap do |sitemap|
      sitemap.default_host = self.class.host
      sitemap.public_path = "#{output_directory}/"
      sitemap.sitemaps_path = nil
      sitemap.compress = :all_but_first
      sitemap.create_index = true
      sitemap.include_root = false
      sitemap.verbose = false
    end

    SitemapGenerator::Sitemap.create do
      urls.each_url do |path, options = {}|
        # Google ignores changefreq and priority, and defaulting lastmod to now
        # would tell it every static page changed on the night we last ran. The
        # gem fills all three in unless they are explicitly nil.
        add(path, changefreq: nil, priority: nil, lastmod: nil, **options)
      end
    end
  end

  def swap_into_place(scratch)
    current = self.class.directory
    previous = sibling_directory('old')

    FileUtils.rm_rf(previous)
    File.rename(current, previous) if current.exist?
    File.rename(scratch, current)
    FileUtils.rm_rf(previous)
  end

  def sibling_directory(suffix)
    Pathname.new("#{self.class.directory}.#{suffix}")
  end
end
