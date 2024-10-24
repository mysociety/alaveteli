# == Schema Information
# Schema version: 20241024140606
#
# Table name: insights
#
#  id              :bigint           not null, primary key
#  info_request_id :bigint
#  model           :string
#  temperature     :decimal(8, 2)
#  prompt_template :text
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

    it 'requires prompt_template' do
      insight = FactoryBot.build(:insight)
      insight.prompt_template = nil
      expect(insight).not_to be_valid
    end
  end

  describe 'callbacks' do
    it 'queues InsightJob after create' do
      expect(InsightJob).to receive(:perform_later)
      FactoryBot.create(:insight)
    end
  end

  describe '#duration' do
    it 'returns nil when total_duration is not present' do
      insight = FactoryBot.build(:insight)
      expect(insight.duration).to be_nil
    end

    it 'returns formatted duration when total_duration exists' do
      insight = FactoryBot.build(:insight)
      insight.output = { 'total_duration' => 3_000_000_000 }
      expect(insight.duration).to eq('3 seconds')
    end
  end

  describe '#prompt' do
    it 'replaces [initial_request] with first outgoing message body' do
      outgoing_message = instance_double(
        OutgoingMessage, body: 'message content'
      )
      insight = FactoryBot.build(
        :insight, prompt_template: 'Template with [initial_request]'
      )

      allow(insight).to receive(:outgoing_messages).
        and_return([outgoing_message])

      expect(insight.prompt).to eq('Template with message content')
    end

    it 'removes content tags from outgoing message body' do
      outgoing_message = instance_double(
        OutgoingMessage, body: 'Foo <|start_bar|>Bar<|end_bar|> Baz'
      )
      insight = FactoryBot.build(:insight, prompt_template: '[initial_request]')

      allow(insight).to receive(:outgoing_messages).
        and_return([outgoing_message])

      expect(insight.prompt).to eq('Foo  Baz')
    end

    it 'removes single tags from outgoing message body' do
      outgoing_message = instance_double(
        OutgoingMessage, body: 'Foo <|eot_id|> Bar'
      )
      insight = FactoryBot.build(:insight, prompt_template: '[initial_request]')

      allow(insight).to receive(:outgoing_messages).
        and_return([outgoing_message])

      expect(insight.prompt).to eq('Foo  Bar')
    end
  end

  describe '#response' do
    it 'returns response from output' do
      insight = FactoryBot.build(:insight)
      insight.output = { 'response' => 'test response' }
      expect(insight.response).to eq('test response')
    end
  end
end
