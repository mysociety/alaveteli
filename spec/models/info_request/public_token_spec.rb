require 'spec_helper'

RSpec.describe InfoRequest do
  describe '#enable_public_token!' do
    let(:info_request) { FactoryBot.build(:info_request) }

    it 'generates public token' do
      allow(Digest::UUID).to receive(:uuid_v4).and_return('unique-token')
      expect { info_request.enable_public_token! }.to(
        change(info_request, :public_token).from(nil).to('unique-token')
      )
    end

    it 'saves public token' do
      info_request.enable_public_token!
      expect(info_request.changes).to be_empty
    end
  end

  describe '#disable_public_token!' do
    let(:info_request) do
      FactoryBot.build(:info_request, public_token: 'old-token')
    end

    it 'generates public token' do
      expect { info_request.disable_public_token! }.to(
        change(info_request, :public_token).from('old-token').to(nil)
      )
    end

    it 'saves public token' do
      info_request.disable_public_token!
      expect(info_request.changes).to be_empty
    end
  end
end
