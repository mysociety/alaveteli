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

RSpec.describe Workflow::Jobs::AnonymizeText, type: :model do
  let(:job) { FactoryBot.build(:anonymize_text) }

  it 'inherits from Workflow::Job' do
    expect(job).to be_a(Workflow::Job)
  end

  describe '#perform' do
    it 'calls an external command to anonymize text' do
      allow(IO).to receive(:popen).and_return('Anonymized text')
      expect(job.perform).to eq('Anonymized text')
    end
  end

  describe '#content_type' do
    it 'returns the correct content type' do
      expect(job.content_type).to eq('text/plain')
    end
  end
end
