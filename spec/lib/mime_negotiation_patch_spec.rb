# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'MimeNegotiation#formats', :type => :request do

  class AnonymousController < ApplicationController
    def hello
      render :text => "Hello world #{request.formats.first.to_s}!"
    end

    def all
      render :text => self.formats.inspect
    end

    def get_file
      render :file => "#{Rails.root}/README.md", :layout => false
    end
  end

  before do
    @routes.draw do
      get 'file'  => 'anonymous#get_file'
      get 'all'   => 'anonymous#all'
      get 'hello' => 'anonymous#hello'
    end
  end

  after do
    Rails.application.reload_routes!
  end

  it 'returns HTML given a */* Accept header' do
    get '/hello', {}, { 'HTTP_ACCEPT' => '*/*' }
    expect(response.body).to eq 'Hello world */*!'
  end

  it 'returns HTML given a js or */* Accept header' do
    get '/hello', {}, { 'HTTP_ACCEPT' => 'text/javascript, */*' }
    expect(response.body).to eq 'Hello world text/html!'
  end

  it 'returns javascript given a js or */* Accept header on xhr' do
    xhr :get, '/hello', {}, { 'HTTP_ACCEPT' => 'text/javascript, */*' }
    expect(response.body).to eq 'Hello world text/javascript!'
  end

  it 'ignores unregistered mimetypes' do
    get '/all', {}, { 'HTTP_ACCEPT' => 'text/plain, mime/another' }
    expect(response.body).to eq '[:text]'
  end

  it 'does not allow a modified accept header to render arbitrary files' do
    get '/file',
        {},
        { 'HTTP_ACCEPT' => "../../../../../../../../../../etc/hosts{{" }
    expect(response.body).to include '# Welcome to Alaveteli!'
  end

end
