require 'spec_helper'

RSpec.describe CitationsController, type: :controller do
  describe 'GET new' do
    it 'should be successful' do
      get :new, params: { url_title: 'request_title' }
      expect(response).to be_successful
    end
  end

  describe 'POST create' do
    it 'should be successful' do
      post :create, params: { url_title: 'request_title' }
      expect(response).to be_successful
    end
  end
end
