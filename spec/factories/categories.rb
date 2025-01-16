# == Schema Information
# Schema version: 20231127110827
#
# Table name: categories
#
#  id           :integer          not null, primary key
#  category_tag :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :category_root, class: Category do
    title { 'Root node' }
  end

  factory :category do
    title { 'Popular authorities' }
    description { 'The most popular authorities' }
    category_tag { 'popular_agency' }

    parents { [association(:category_root)] }

    trait :public_body do
      parents { [PublicBody.category_root] }
    end

    trait :info_request do
      parents { [InfoRequest.category_root] }
    end
  end
end
