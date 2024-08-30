# == Schema Information
# Schema version: 20240905062817
#
# Table name: chunks
#
#  id                  :bigint           not null, primary key
#  info_request_id     :bigint
#  incoming_message_id :bigint
#  foi_attachment_id   :bigint
#  text                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  embedding           :vector(4096)
#
require 'spec_helper'

RSpec.describe Chunk, type: :model do
  describe 'associations' do
    it 'belongs to an info request' do
      chunk = FactoryBot.build(
        :chunk, info_request: FactoryBot.build(:info_request)
      )
      expect(chunk.info_request).to be_a(InfoRequest)
    end

    it 'belongs to an incoming message' do
      chunk = FactoryBot.build(
        :chunk, incoming_message: FactoryBot.build(:incoming_message)
      )
      expect(chunk.incoming_message).to be_a(IncomingMessage)
    end

    it 'belongs to an FOI attachment' do
      chunk = FactoryBot.build(
        :chunk, foi_attachment: FactoryBot.build(:foi_attachment)
      )
      expect(chunk.foi_attachment).to be_a(FoiAttachment)
    end
  end

  describe 'validations' do
    it 'is valid without an info request' do
      chunk = FactoryBot.build(:chunk, info_request: nil)
      expect(chunk).to be_valid
    end

    it 'is valid without an incoming message' do
      chunk = FactoryBot.build(:chunk, incoming_message: nil)
      expect(chunk).to be_valid
    end

    it 'is valid without an FOI attachment' do
      chunk = FactoryBot.build(:chunk, foi_attachment: nil)
      expect(chunk).to be_valid
    end
  end

  describe 'vectorsearch' do
    it 'includes the vectorsearch module' do
      expect(described_class.included_modules).
        to include(LangchainrbRails::ActiveRecord::Hooks)
    end
  end

  describe 'callbacks' do
    it 'calls upsert_to_vectorsearch after save' do
      chunk = FactoryBot.build(:chunk)
      expect(chunk).to receive(:upsert_to_vectorsearch)
      chunk.save
    end
  end

  describe '#as_vector' do
    it 'returns the text of the chunk' do
      chunk = FactoryBot.build(:chunk, text: 'Sample text')
      expect(chunk.as_vector).to eq('Sample text')
    end
  end
end
