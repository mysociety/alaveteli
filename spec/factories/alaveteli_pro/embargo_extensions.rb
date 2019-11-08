# == Schema Information
# Schema version: 20220322100510
#
# Table name: embargo_extensions
#
#  id                 :bigint           not null, primary key
#  embargo_id         :bigint
#  extension_duration :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryBot.define do
  factory :embargo_extension, :class => AlaveteliPro::EmbargoExtension do
    embargo
    extension_duration { '3_months' }
  end
end
