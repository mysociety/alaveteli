require 'spec_helper'

RSpec.describe StripEmptySessions do
  def make_response(session_data, response_headers)
    app = lambda do |env|
      env['rack.session'] = session_data
      return [200, response_headers, ['content']]
    end

    app = StripEmptySessions.new(app, key: 'mykey', path: '', httponly: true)

    Rack::MockRequest.new(app).get('/', HTTP_ACCEPT: 'text/html', lint: true)
  end

  let(:application_response_headers) do
    { 'Content-Type' => 'text/html',
      'Set-Cookie' => 'mykey=f274c61a35320c52d45; path=/; HttpOnly'.freeze }
  end

  let(:no_set_cookie_header) do
    { 'Content-Type' => 'text/html' }
  end

  let(:several_set_cookie_headers) do
    { 'Content-Type' => 'text/html',
      'Set-Cookie' => ['mykey=f274c61a35320c52d45; path=/; HttpOnly',
                       'other=mydata'].join("\n").freeze }
  end

  context 'there is meaningful data in the session' do
    let(:session_data) do
      { 'some_real_data' => 'important',
        'session_id' => 'my_session_id',
        '_csrf_token' => 'hi_there' }
    end

    it 'does not prevent a cookie being set' do
      response = make_response(session_data, application_response_headers)

      expect(response.headers['Set-Cookie']).
        to eq('mykey=f274c61a35320c52d45; path=/; HttpOnly')
    end
  end

  context 'there is no meaningful data in the session' do
    let(:session_data) do
      { 'session_id' => 'my_session_id',
        '_csrf_token' => 'hi_there' }
    end

    it 'does not strip any other header' do
      response = make_response(session_data, application_response_headers)
      expect(response.headers['Content-Type']).to eq('text/html')
    end

    it 'strips the session cookie setting header ' do
      response = make_response(session_data, application_response_headers)
      expect(response.headers['Set-Cookie']).to eq('')
    end

    it 'strips the session cookie setting header even with a locale' do
      session_data['locale'] = 'en'
      response = make_response(session_data, application_response_headers)
      expect(response.headers['Set-Cookie']).to eq('')
    end

    it 'does not strip the session cookie setting for admins' do
      session_data['using_admin'] = 1
      response = make_response(session_data, application_response_headers)

      expect(response.headers['Set-Cookie']).
        to eq('mykey=f274c61a35320c52d45; path=/; HttpOnly')
    end

    it 'strips only the session cookie setting header if there are several' do
      response = make_response(session_data, several_set_cookie_headers)
      expect(response.headers['Set-Cookie']).to eq('other=mydata')
    end

    it 'does not add a set-cookie header if the application does not set it' do
      response = make_response(session_data, no_set_cookie_header)
      expect(response.headers['Set-Cookie']).to eq(nil)
    end
  end
end
