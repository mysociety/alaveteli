require 'spec_helper'

RSpec.describe 'when generating URLs' do
  before do
    AlaveteliLocalization.set_locales('es en en_GB', 'es')
  end

  it 'sets Content-Language to default locale' do
    get '/'
    expect(response.headers['Content-Language']).to eq('es')
  end

  it 'redirects to remove old style URL locale' do
    get '/en'
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('es')
  end

  it 'redirects to remove locale param without switching locale' do
    get '/', params: { locale: 'en' }
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('es')
  end

  it 'sets the correct Content-Language via the locale switcher' do
    put '/locale', params: { locale: 'en', return_to: '/' }
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en')
  end

  it 'redirects to remove locale param but keep other params' do
    get '/body/list/all', params: { locale: 'en', page: 2 }
    expect(response).to redirect_to('/body/list/all?page=2')
  end

  it 'sets and remember the correct Content-Language via request header' do
    get '/', headers: { 'HTTP_ACCEPT_LANGUAGE' => 'en' } # set
    get '/' # remember
    expect(response.headers['Content-Language']).to eq('en')
  end

  it 'remembers user selection of default locale when browser prefers different language' do
    headers = { 'HTTP_ACCEPT_LANGUAGE' => 'en' }
    put '/locale', params: { locale: 'es', return_to: '/' }, headers: headers
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('es')

    get '/', headers: headers
    expect(response.headers['Content-Language']).to eq('es')
  end

  it 'sets correct Content-Language via underscored locale param' do
    put '/locale', params: { locale: 'en_GB', return_to: '/' }
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en-GB')
  end

  it 'sets correct Content-Language via hyphenated locale param' do
    put '/locale', params: { locale: 'en-GB', return_to: '/' }
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en-GB')
  end

  it 'falls back to the language if the territory is unknown' do
    put '/locale', params: { locale: 'en_US', return_to: '/' }
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en')
  end

  it 'falls back to the default if the requested locale is unknown' do
    put '/locale', params: { locale: 'unknown', return_to: '/' }
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('es')
  end

  context 'when handling public body requests' do
    before do
      body = FactoryBot.create(:public_body)

      AlaveteliLocalization.with_locale('en') do
        body.short_name = 'english_short'
        body.save!
      end

      AlaveteliLocalization.with_locale('es') do
        body.short_name = 'spanish_short'
        body.save!
      end
    end

    it 'should redirect requests for a public body to the canonical name in the current locale' do
      get '/body/english_short'
      expect(response).to redirect_to '/body/spanish_short'
    end

    it 'should remember a filter view when redirecting a public body request to the canonical name' do
      get '/body/english_short/successful'
      expect(response).to redirect_to '/body/spanish_short/successful'
    end

    it 'does not switch locale for an old style URL locale' do
      put '/locale', params: { locale: 'en', return_to: '/' }
      get '/es/body/spanish_short'
      expect(response).to redirect_to '/body/spanish_short'
      follow_redirect!
      expect(response).to redirect_to '/body/english_short'
    end
  end
end
