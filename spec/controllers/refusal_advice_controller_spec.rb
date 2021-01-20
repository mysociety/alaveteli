require 'spec_helper'

RSpec.describe RefusalAdviceController do
  describe 'POST #create' do
    it 'returns a success' do
      post :create
      expect(response).to be_successful
    end
  end
end
