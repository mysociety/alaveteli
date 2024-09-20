# == Schema Information
# Schema version: 20240905062817
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

RSpec.describe Workflow::Job, type: :model do
  describe 'included modules' do
    it 'includes Workflow::Source' do
      expect(Workflow::Job.included_modules).to include(Workflow::Source)
    end

    it 'includes Workflow::Transitions' do
      expect(Workflow::Job.included_modules).to include(Workflow::Transitions)
    end
  end

  describe 'metadata serialization' do
    it 'serializes metadata as JSON' do
      job = FactoryBot.build(:workflow_job, metadata: { key: 'value' })
      expect(job.metadata).to eq({ key: 'value' })
    end

    it 'defaults to an empty hash' do
      job = FactoryBot.build(:workflow_job)
      expect(job.metadata).to eq({})
    end
  end

  describe 'associations' do
    it 'belongs to a polymorphic resource' do
      resource = FactoryBot.build(:foi_attachment)
      job = FactoryBot.build(:workflow_job, resource:  resource)
      expect(job.resource).to be_a(FoiAttachment)

      resource = FactoryBot.build(:incoming_message)
      job = FactoryBot.build(:workflow_job, resource:  resource)
      expect(job.resource).to be_a(IncomingMessage)
    end

    it 'belongs to an optional parent' do
      job = FactoryBot.build(:workflow_job, parent: nil)
      expect(job).to be_valid
    end
  end

  describe '#perform' do
    it 'raises NotImplementedError' do
      job = FactoryBot.build(:workflow_job)
      expect { job.perform }.to raise_error(NotImplementedError)
    end
  end

  describe '#content_type' do
    it 'raises NotImplementedError' do
      job = FactoryBot.build(:workflow_job)
      expect { job.content_type }.to raise_error(NotImplementedError)
    end
  end
end
