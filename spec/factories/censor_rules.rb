# == Schema Information
#
# Table name: censor_rules
#
#  id                :integer          not null, primary key
#  text              :text             not null
#  replacement       :text             not null
#  last_edit_editor  :string           not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean          default(FALSE), not null
#  case_sensitive    :boolean          default(TRUE), not null
#  ignore_diacritics :boolean          default(FALSE), not null
#  censorable_type   :string
#  censorable_id     :bigint
#

FactoryBot.define do
  factory :censor_rule do
    text { 'some text to redact' }
    replacement { '[REDACTED]' }
    last_edit_editor { 'FactoryBot' }
    last_edit_comment { 'Modified by rspec' }

    factory :regexp_censor_rule do
      text { '\w+@\w+' }
      regexp { true }
    end

    factory :info_request_censor_rule do
      association :censorable, factory: :info_request
    end

    factory :public_body_censor_rule do
      association :censorable, factory: :public_body
    end

    factory :user_censor_rule do
      association :censorable, factory: :user
    end

    factory :global_censor_rule do
    end

    trait :case_insensitive do
      case_sensitive { false }
    end

    trait :ignore_diacritics do
      ignore_diacritics { true }
    end
  end
end
