require 'spec_helper'

RSpec.describe SitemapsController, type: :controller do
  let(:directory) { Pathname.new(Dir.mktmpdir) }

  before { allow(Sitemap).to receive(:directory).and_return(directory) }
  after { FileUtils.rm_rf(directory) }

  def write_sitemap(filename)
    directory.join(filename).write('<urlset />')
  end

  describe 'GET show' do
    context 'when a sitemap has been generated' do
      before { write_sitemap('sitemap.xml') }

      it 'serves the index' do
        get :show
        expect(response).to be_successful
      end

      it 'serves the index as XML' do
        get :show
        expect(response.media_type).to eq 'application/xml'
      end

      it 'allows the response to be cached' do
        get :show
        expect(response.headers['Cache-Control']).
          to include "max-age=#{24.hours.to_i}"
      end
    end

    context 'when a numbered sitemap has been generated' do
      before { write_sitemap('sitemap1.xml.gz') }

      it 'serves it as gzip' do
        get :show, params: { number: '1' }
        expect(response).to be_successful
        expect(response.media_type).to eq 'application/gzip'
      end
    end

    # ApplicationController turns RouteNotFound into a 404. Controller specs
    # re-raise instead of running that handler, so the status is asserted in
    # spec/integration/sitemap_spec.rb.
    context 'when no sitemap has been generated' do
      it 'raises RouteNotFound' do
        expect { get :show }.
          to raise_error(ApplicationController::RouteNotFound)
      end
    end

    context 'when sitemaps are disabled' do
      before do
        write_sitemap('sitemap.xml')
        allow(Sitemap).to receive(:enabled?).and_return(false)
      end

      it 'raises RouteNotFound' do
        expect { get :show }.
          to raise_error(ApplicationController::RouteNotFound)
      end
    end
  end
end
