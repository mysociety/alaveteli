# -*- encoding : utf-8 -*-
require 'spec_helper'

describe StripEmptySessions do
  def make_response(session_data, response_headers)
    app = lambda do |env|
      env['rack.session'] = session_data
      return [200, response_headers, ['content']]
    end

    app = StripEmptySessions.new(app, key: 'mykey', path: '', httponly: true)
    Rack::MockRequest.new(app).get('/', 'HTTP_ACCEPT' => 'text/html')
  end

  it 'does not prevent a cookie being set if there is data in the session' do
    session_data = { 'some_real_data' => 'important',
                     'session_id' => 'my_session_id',
                     '_csrf_token' => 'hi_there' }

    application_response_headers = {
      'Content-Type' => 'text/html',
      'Set-Cookie' => 'mykey=f274c61a35320c52d45; path=/; HttpOnly'
    }

    response = make_response(session_data, application_response_headers)

    expect(response.headers['Set-Cookie']).
      to eq('mykey=f274c61a35320c52d45; path=/; HttpOnly')
  end

  describe 'if there is no meaningful data in the session' do

    before do
      @session_data = { 'session_id' => 'my_session_id',
                        '_csrf_token' => 'hi_there' }
    end

    it 'does not strip any other header' do
      application_response_headers = {
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'mykey=f274c61a35320c52d45; path=/; HttpOnly'
      }

      response = make_response(@session_data, application_response_headers)

      expect(response.headers['Content-Type']).to eq('text/html')
    end

    it 'strips the session cookie setting header ' do
      application_response_headers = {
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'mykey=f274c61a35320c52d45; path=/; HttpOnly'
      }

      response = make_response(@session_data, application_response_headers)

      expect(response.headers['Set-Cookie']).to eq('')
    end

    it 'strips the session cookie setting header even with a locale' do
      @session_data['locale'] = 'en'

      application_response_headers = {
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'mykey=f274c61a35320c52d45; path=/; HttpOnly'
      }

      response = make_response(@session_data, application_response_headers)

      expect(response.headers['Set-Cookie']).to eq('')
    end

    it 'does not strip the session cookie setting for admins' do
      @session_data['using_admin'] = 1

      application_response_headers = {
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'mykey=f274c61a35320c52d45; path=/; HttpOnly'
      }

      response = make_response(@session_data, application_response_headers)

      expect(response.headers['Set-Cookie']).
        to eq('mykey=f274c61a35320c52d45; path=/; HttpOnly')
    end

    it 'strips only the session cookie setting header if there are several' do
      application_response_headers = {
        'Content-Type' => 'text/html',
        'Set-Cookie' => [
          'mykey=f274c61a35320c52d45; path=/; HttpOnly',
          'other=mydata'
        ]
      }

      response = make_response(@session_data, application_response_headers)

      expect(response.headers['Set-Cookie']).to eq(['other=mydata'])
    end

  end
end
