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

  describe '#date' do
    it 'returns nil if there is not a created parameter' do
      webhook.params = { 'created' => nil }
      expect(webhook.date).to be_nil
    end

    it 'returns created parameter and typecast as Time' do
      time = Time.now.utc.change(usec: 0)
      webhook.params = { 'created' => time.to_i }
      expect(webhook.date).to eq time
    end
  end

  describe '#customer_id' do
    it 'returns nil if there is not a data parameter' do
      webhook.params = { 'data' => nil }
      expect(webhook.date).to be_nil
    end

    it 'returns nil if there is not a data.object parameter' do
      webhook.params = { 'data' => { 'object' => nil } }
      expect(webhook.date).to be_nil
    end

    it 'returns nil if there is not a data.object.customer parameter' do
      webhook.params = { 'data' => { 'object' => { 'customer' => nil } } }
      expect(webhook.date).to be_nil
    end

    it 'returns data.object.customer parameter' do
      webhook.params = { 'data' => { 'object' => { 'customer' => 'cus_123' } } }
      expect(webhook.customer_id).to eq 'cus_123'
    end
  end
end
