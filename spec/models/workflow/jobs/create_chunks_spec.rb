# == Schema Information
# Schema version: 20240916160558
#
# Table name: workflow_jobs
#
#  id            :bigint           not null, primary key
#  type          :string
#  resource_type :string
#  resource_id   :bigint
#  status        :integer
#  parent_id     :bigint
#  metadata      :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'spec_helper'

RSpec.describe Workflow::Jobs::CreateChunks, type: :model do
  let(:job) { FactoryBot.build(:create_chunks) }

  it 'inherits from Workflow::Job' do
    expect(job).to be_a(Workflow::Job)
  end

  describe '#perform' do
    it 'creates a chunk for the resource' do
      VCR.use_cassette('test_chunk') do
        resource = FactoryBot.create(:foi_attachment)
        job.resource = resource
        job.source = 'Test chunk'

        expect { job.perform }.to change { resource.chunks.count }.by(1)
      end
    end
  end

  describe '#content_type' do
    it 'returns the correct content type' do
      expect(job.content_type).to eq('application/json')
    end
  end

  describe 'callbacks' do
    it 'destroys associated chunks when the job is destroyed' do
      VCR.use_cassette('test_chunk') do
        resource = FactoryBot.create(
          :foi_attachment, chunks: [FactoryBot.build(:chunk)]
        )
        job.resource = resource
        job.save!

        expect { job.destroy }.to change { resource.chunks.count }.to(0)
      end
    end
  end
end
