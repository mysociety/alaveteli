require 'spec_helper'

RSpec.describe Webhook, type: :model do
  let(:webhook) { FactoryBot.build(:webhook) }

  describe 'validations' do
    specify { expect(webhook).to be_valid }

    it 'requires params' do
      webhook.params = nil
      expect(webhook).not_to be_valid
    end
  end
end
