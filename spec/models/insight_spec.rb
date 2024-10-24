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
end
