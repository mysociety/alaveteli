# == Schema Information
# Schema version: 20241024140606
#
# Table name: insights
#
#  id              :bigint           not null, primary key
#  info_request_id :bigint
#  model           :string
#  temperature     :decimal(8, 2)
#  template        :text
#  output          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'spec_helper'

RSpec.describe Insight, type: :model do
  describe 'associations' do
    it 'belongs to info_request' do
      insight = FactoryBot.build(:insight)
      expect(insight.info_request).to be_a(InfoRequest)
    end

    it 'has many outgoing_messages through info_request' do
      insight = FactoryBot.build(:insight)
      expect(insight.outgoing_messages).to all(be_a(OutgoingMessage))
    end
  end

  describe 'validations' do
    it 'requires info_request' do
      insight = FactoryBot.build(:insight)
      insight.info_request = nil
      expect(insight).not_to be_valid
    end

    it 'requires model' do
      insight = FactoryBot.build(:insight)
      insight.model = nil
      expect(insight).not_to be_valid
    end

    it 'requires temperature' do
      insight = FactoryBot.build(:insight)
      insight.temperature = nil
      expect(insight).not_to be_valid
    end

    it 'requires template' do
      insight = FactoryBot.build(:insight)
      insight.template = nil
      expect(insight).not_to be_valid
    end
  end

  describe 'callbacks' do
    it 'queues InsightJob after create' do
      expect(InsightJob).to receive(:perform_later)
      FactoryBot.create(:insight)
    end
  end

  describe '#prompt' do
    it 'replaces [initial_request] with first outgoing message body' do
      outgoing_message = instance_double(
        OutgoingMessage, body: 'message content'
      )
      insight = FactoryBot.build(
        :insight, template: 'Template with [initial_request]'
      )

      allow(insight).to receive(:outgoing_messages).
        and_return([outgoing_message])

      expect(insight.prompt).to eq('Template with message content')
    end
  end
end
