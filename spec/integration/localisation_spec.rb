require 'spec_helper'

RSpec.describe 'when generating URLs' do
  before do
    AlaveteliLocalization.set_locales('es en en_GB', 'es')
  end

  it 'sets Content-Language to default locale' do
    get '/'
    expect(response.headers['Content-Language']).to eq('es')
  end

  it 'redirects to locale param with old style URL locale' do
    get '/es'
    expect(response).to redirect_to('/?locale=es')
    follow_redirect!
    expect(response).to redirect_to('/')
  end

  it 'sets the correct Content-Language via locale param' do
    get '/', params: { locale: 'en' }
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en')
  end

  it 'sets and remember the correct Content-Language via request header' do
    get '/', headers: { 'HTTP_ACCEPT_LANGUAGE' => 'en' } # set
    get '/' # remember
    expect(response.headers['Content-Language']).to eq('en')
  end

  it 'sets correct Content-Language via underscored locale param' do
    get '/', params: { locale: 'en_GB' }
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en-GB')
  end

  it 'sets correct Content-Language via hyphenated locale param' do
    get '/', params: { locale: 'en-GB' }
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en-GB')
  end

  it 'falls back to the language if the territory is unknown' do
    get '/', params: { locale: 'en_US' }
    expect(response).to redirect_to('/')
    follow_redirect!
    expect(response.headers['Content-Language']).to eq('en')
  end

  it 'falls back to the default if the requested locale is unknown' do
    get '/', params: { locale: 'unknown' }
    expect(response).to redirect_to('/')
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

    it 'should redirect requests for a public body in a locale to the canonical name in that locale' do
      get '/es/body/english_short'
      follow_redirect!
      expect(response).to redirect_to '/body/spanish_short'
    end

    it 'should remember a filter view when redirecting a public body request to the canonical name' do
      get '/es/body/english_short/successful'
      follow_redirect!
      expect(response).to redirect_to '/body/spanish_short/successful'
    end
  end
end
