require 'spec_helper'

RSpec.describe RobotsController, type: :controller do
  describe 'GET show' do
    it 'is successful' do
      get :show
      expect(response).to be_successful
    end

    it 'renders as plain text' do
      get :show
      expect(response.media_type).to eq 'text/plain'
    end

    it 'allows the response to be cached' do
      get :show
      expect(response.headers['Cache-Control']).
        to include "max-age=#{24.hours.to_i}"
    end
  end
end
