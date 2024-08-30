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
FactoryBot.define do
  factory :workflow_job, class: 'Workflow::Job' do
    resource { build(:foi_attachment) }

    factory :convert_to_text, class: 'Workflow::Jobs::ConvertToText' do
      source { '' }
    end

    factory :anonymize_text, class: 'Workflow::Jobs::AnonymizeText' do
      source { '' }
    end

    factory :create_chunks, class: 'Workflow::Jobs::CreateChunks' do
      source { '' }
    end
  end
end
