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

RSpec.describe Workflow::Jobs::ConvertToText, type: :model do
  let(:job) { FactoryBot.build(:convert_to_text) }

  it 'inherits from Workflow::Job' do
    expect(job).to be_a(Workflow::Job)
  end

  describe '#perform' do
    it 'converts HTML to plain text' do
      job.source = '<p>Hello <strong>World</strong></p>'
      expect(job.perform).to eq('Hello World')
    end
  end

  describe '#content_type' do
    it 'returns the correct content type' do
      expect(job.content_type).to eq('text/plain')
    end
  end
end
