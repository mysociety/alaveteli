require 'spec_helper'

RSpec.describe Sitemap do
  let(:urls) do
    [].tap do |collected|
      subject.each_url { |path, options| collected << [path, options] }
    end
  end

  def paths
    urls.map(&:first)
  end

  def options_for(info_request)
    urls.find { |path, _| path.end_with?(info_request.url_title) }.last
  end

  describe '.enabled?' do
    it 'follows the ENABLE_SITEMAP configuration' do
      allow(AlaveteliConfiguration).
        to receive(:enable_sitemap).and_return(false)
      expect(described_class.enabled?).to eq false
    end
  end

  describe '.path_for' do
    it 'leaves the index uncompressed so it can be served at /sitemap.xml' do
      expect(described_class.path_for.basename.to_s).to eq 'sitemap.xml'
    end

    it 'compresses the sitemaps the index points at' do
      expect(described_class.path_for(2).basename.to_s).to eq 'sitemap2.xml.gz'
    end
  end

  describe '.url' do
    it 'is absolute, as the sitemap protocol requires' do
      allow(AlaveteliConfiguration).
        to receive(:domain).and_return('example.com')
      allow(AlaveteliConfiguration).
        to receive(:force_ssl).and_return(true)
      expect(described_class.url).to eq 'https://example.com/sitemap.xml'
    end
  end

  describe '#each_url' do
    it 'includes a searchable request' do
      info_request = FactoryBot.create(:info_request)
      expect(paths).to include "/request/#{info_request.url_title}"
    end

    it 'excludes an embargoed request' do
      info_request = FactoryBot.create(:info_request, :embargoed)
      expect(paths).to_not include "/request/#{info_request.url_title}"
    end

    # backpage means "public, but keep it out of search engines", so listing it
    # in a sitemap would contradict the X-Robots-Tag the page already sends.
    it 'excludes a backpage request' do
      info_request = FactoryBot.create(:info_request, :backpage)
      expect(paths).to_not include "/request/#{info_request.url_title}"
    end

    it 'excludes a hidden request' do
      info_request = FactoryBot.create(:info_request, :hidden)
      expect(paths).to_not include "/request/#{info_request.url_title}"
    end

    it 'excludes a requester only request' do
      info_request = FactoryBot.create(:info_request, :requester_only)
      expect(paths).to_not include "/request/#{info_request.url_title}"
    end

    it 'dates a request by its last event' do
      info_request = FactoryBot.create(:info_request)
      expect(options_for(info_request)[:lastmod]).
        to eq info_request.last_event_time
    end

    it 'falls back to the update time when a request has logged no events' do
      info_request = FactoryBot.create(:info_request)
      info_request.update_column(:last_event_time, nil)

      expect(options_for(info_request)[:lastmod]).
        to be_within(1.second).of(info_request.updated_at)
    end

    it 'includes a visible authority' do
      public_body = FactoryBot.create(:public_body)
      expect(paths).to include "/body/#{public_body.url_name}"
    end

    # Their pages still hold historic requests worth indexing.
    it 'includes a defunct authority' do
      public_body = FactoryBot.create(:public_body, :defunct)
      expect(paths).to include "/body/#{public_body.url_name}"
    end

    it 'excludes the internal admin authority' do
      public_body = PublicBody.internal_admin_body
      expect(paths).to_not include "/body/#{public_body.url_name}"
    end

    it 'includes the static pages worth indexing' do
      expect(paths).to include '/browse', '/list', '/body', '/help/about'
    end

    it 'excludes pages which robots.txt disallows' do
      expect(paths.grep(%r{/search|/profile|/feed})).to be_empty
    end
  end
end
