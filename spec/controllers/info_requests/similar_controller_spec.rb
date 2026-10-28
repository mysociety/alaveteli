require 'spec_helper'

RSpec.describe InfoRequests::SimilarController do
  describe 'GET #index' do
    let(:badger_request) { info_requests(:badger_request) }

    it 'routes from the request similar path' do
      expect(get: '/request/why_do_you_have_such_a_fancy_dog/similar').
        to route_to('info_requests/similar#index',
                    url_title: 'why_do_you_have_such_a_fancy_dog')
    end

    it 'renders the index template' do
      get :index, params: { url_title: badger_request.url_title }
      expect(response).to render_template('info_requests/similar/index')
    end

    it 'assigns the request' do
      get :index, params: { url_title: badger_request.url_title }
      expect(assigns[:info_request]).to eq(badger_request)
    end

    it 'assigns a results object with similar requests' do
      expected = InfoRequest.all.reject { |request| request == badger_request }
      events = expected.map { |r| r.info_request_events.first }
      stub_similar_requests(items: events, total: events.size)

      get :index, params: { url_title: badger_request.url_title }

      results = assigns[:results].results
      expect(results.map { |result| result[:model].info_request }).
        to match_array(expected)
    end

    it 'raises ActiveRecord::RecordNotFound for non-existent paths' do
      expect {
        get :index, params: { url_title: 'there_is_really_no_such_path' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'fetches a single page of up to 25 similar requests' do
      stub_similar_requests
      get :index, params: { url_title: badger_request.url_title }
      expect(Search.similar(badger_request)).
        to have_received(:results).with(per_page: 25)
    end

    it 'ignores the page param' do
      stub_similar_requests
      get :index, params: { url_title: badger_request.url_title, page: 100 }
      expect(Search.similar(badger_request)).
        to have_received(:results).with(per_page: 25)
    end

    it 'raises ActiveRecord::RecordNotFound if the request is embargoed' do
      badger_request.create_embargo(publish_at: Time.zone.now + 3.days)
      expect {
        get :index, params: { url_title: badger_request.url_title }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'adds noindex, nofollow header' do
      get :index, params: { url_title: badger_request.url_title }
      expect(response.headers['X-Robots-Tag']).to eq 'noindex, nofollow'
    end
  end
end
