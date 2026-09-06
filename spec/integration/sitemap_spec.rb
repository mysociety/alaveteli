require 'spec_helper'

RSpec.describe 'sitemap', type: :request do
  SITEMAP_NS = 'http://www.sitemaps.org/schemas/sitemap/0.9'.freeze

  let(:directory) { Pathname.new(Dir.mktmpdir) }

  before { allow(Sitemap).to receive(:directory).and_return(directory) }
  after { FileUtils.rm_rf(directory) }

  context 'before it has been generated', local_requests: false do
    it 'is not found' do
      get '/sitemap.xml'
      expect(response.status).to eq 404
    end
  end

  context 'once generated' do
    before do
      FactoryBot.create(:info_request)
      Sitemap.generate!
      get '/sitemap.xml'
    end

    let(:document) { Nokogiri::XML(response.body) }

    it 'is served as XML' do
      expect(response).to be_successful
      expect(response.media_type).to eq 'application/xml'
    end

    it 'is a sitemap index in the sitemaps.org namespace' do
      expect(document.errors).to be_empty
      expect(document.root.name).to eq 'sitemapindex'
      expect(document.root.namespace.href).to eq SITEMAP_NS
    end

    it 'points only at sitemaps which exist' do
      locations = document.css('sitemap loc').map(&:text)
      expect(locations).to_not be_empty

      locations.each do |location|
        filename = File.basename(URI.parse(location).path)
        expect(directory.join(filename)).to exist
      end
    end

    it 'points at absolute URLs on the configured host' do
      document.css('loc').each do |loc|
        expect(loc.text).to start_with Sitemap.host
      end
    end

    context 'the sitemaps it points at' do
      let(:urlset) do
        path = directory.join('sitemap1.xml.gz')
        Nokogiri::XML(Zlib::GzipReader.open(path, &:read))
      end

      it 'are a urlset in the sitemaps.org namespace' do
        expect(urlset.errors).to be_empty
        expect(urlset.root.name).to eq 'urlset'
        expect(urlset.root.namespace.href).to eq SITEMAP_NS
      end

      it 'give every URL an absolute location' do
        locations = urlset.css('url loc').map(&:text)
        expect(locations).to_not be_empty
        expect(locations).to all(start_with(Sitemap.host))
      end

      it 'date entries in the W3C format search engines expect' do
        modified = urlset.css('url lastmod').map(&:text)
        expect(modified).to_not be_empty
        expect(modified).to all(match(/\A\d{4}-\d{2}-\d{2}(T[\d:.+-]+)?\z/))
      end

      # Naming a URL in a sitemap which robots.txt blocks is a contradiction
      # that Search Console reports as an error.
      it 'list no URL which robots.txt disallows' do
        paths = urlset.css('url loc').map { |loc| URI.parse(loc.text).path }
        disallowed = paths.select { |path| robots_disallows?(path) }

        expect(disallowed).to be_empty
      end
    end
  end

  context 'when disabled', local_requests: false do
    before do
      Sitemap.generate!
      allow(Sitemap).to receive(:enabled?).and_return(false)
    end

    it 'is not found' do
      get '/sitemap.xml'
      expect(response.status).to eq 404
    end

    it 'is not advertised in robots.txt' do
      get '/robots.txt'
      expect(response.body).to_not include 'Sitemap:'
    end
  end

  context 'when enabled' do
    it 'is advertised in robots.txt as an absolute URL' do
      get '/robots.txt'
      expect(response.body).to include "Sitemap: #{Sitemap.url}"
    end
  end

  def robots_rules
    @robots_rules ||= begin
      get '/robots.txt'
      response.body.scan(/^Disallow: (.+)$/).flatten
    end
  end

  # robots.txt patterns are globs, not regexps: `*` matches any run of
  # characters and a trailing `$` anchors to the end of the URL.
  def robots_disallows?(path)
    robots_rules.any? do |rule|
      anchored = rule.end_with?('$')
      pattern = Regexp.escape(anchored ? rule[0..-2] : rule).gsub('\*', '.*')
      pattern = "\\A#{pattern}#{anchored ? '\\z' : ''}"
      path.match?(Regexp.new(pattern))
    end
  end
end
