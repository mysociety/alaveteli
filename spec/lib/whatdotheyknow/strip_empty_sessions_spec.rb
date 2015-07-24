# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
describe WhatDoTheyKnow::StripEmptySessions do

  def make_response(session_data, response_headers)
    app = lambda do |env|
      env['rack.session'] = session_data
      return [200, response_headers, ['content']]
    end
    strip_empty_sessions = WhatDoTheyKnow::StripEmptySessions
    app = strip_empty_sessions.new(app, {:key => 'mykey', :path => '', :httponly => true})
    response = Rack::MockRequest.new(app).get('/', 'HTTP_ACCEPT' => 'text/html')
  end


  it 'should not prevent a cookie being set if there is data in the session' do
    session_data = { 'some_real_data' => 'important',
                     'session_id' => 'my_session_id',
                     '_csrf_token' => 'hi_there' }
    application_response_headers = { 'Content-Type' => 'text/html',
                                     'Set-Cookie' => 'mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly'}
    response = make_response(session_data, application_response_headers)
    response.headers['Set-Cookie'].should == 'mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly'
  end

  describe 'if there is no meaningful data in the session' do

    before do
      @session_data = { 'session_id' => 'my_session_id',
                        '_csrf_token' => 'hi_there' }
    end

    it 'should not strip any other header' do
      application_response_headers = { 'Content-Type' => 'text/html',
                                       'Set-Cookie' => 'mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly'}
      response = make_response(@session_data, application_response_headers)
      response.headers['Content-Type'].should == 'text/html'
    end

    it 'should strip the session cookie setting header ' do
      application_response_headers = { 'Content-Type' => 'text/html',
                                       'Set-Cookie' => 'mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly'}
      response = make_response(@session_data, application_response_headers)
      response.headers['Set-Cookie'].should == ""
    end

    it 'should strip the session cookie setting header even with a locale' do
      @session_data['locale'] = 'en'
      application_response_headers = { 'Content-Type' => 'text/html',
                                       'Set-Cookie' => 'mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly'}
      response = make_response(@session_data, application_response_headers)
      response.headers['Set-Cookie'].should == ""
    end

    it 'should not strip the session cookie setting for admins' do
      @session_data['using_admin'] = 1
      application_response_headers = { 'Content-Type' => 'text/html',
                                       'Set-Cookie' => 'mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly'}
      response = make_response(@session_data, application_response_headers)
      response.headers['Set-Cookie'].should == "mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly"
    end

    it 'should strip the session cookie setting header (but no other cookie setting header) if there is more than one' do
      application_response_headers = { 'Content-Type' => 'text/html',
                                       'Set-Cookie' => ['mykey=f274c61a35320c52d45e9f8d7d4e2649; path=/; HttpOnly',
                                                        'other=mydata']}
      response = make_response(@session_data, application_response_headers)
      response.headers['Set-Cookie'].should == ['other=mydata']
    end

  end
end
