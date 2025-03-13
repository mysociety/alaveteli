# == Schema Information
# Schema version: 20231127110827
#
# Table name: category_relationships
#
#  id         :bigint           not null, primary key
#  parent_id  :integer          not null
#  child_id   :integer          not null
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :category_relationship do
    parent { association :category }
    child { association :category }
    sequence(:position) { _1 }
  end
end
