# == Schema Information
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
FactoryBot.define do
  factory :insight do
    association :info_request
    model { 'llama' }
    temperature { 0.3 }
    prompt_template { 'Some template' }
  end
end
