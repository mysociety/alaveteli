require 'spec_helper'

RSpec.describe User::WithRequest, type: :model do
  describe '#ip' do
    it 'delegates to request' do
      user = mock_model(User)
      request = double(:request, ip: '127.0.0.1')

      instance = User::WithRequest.new(user, request)
      expect(instance.ip).to eq('127.0.0.1')
    end
  end

  describe '#user_agent' do
    it 'delegates to request' do
      user = mock_model(User)
      request = double(:request, user_agent: 'Safari')

      instance = User::WithRequest.new(user, request)
      expect(instance.user_agent).to eq('Safari')
    end
  end
end
