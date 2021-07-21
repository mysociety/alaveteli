# == Schema Information
# Schema version: 20210114161442
#
# Table name: embargo_extensions
#
#  id                 :integer          not null, primary key
#  embargo_id         :integer
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
