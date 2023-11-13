# == Schema Information
# Schema version: 20231127110827
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  category_tag :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  title        :string
#  description  :string
#

FactoryBot.define do
  factory :category do
    title { 'Popular authorities' }
    description { 'The most popular authorities' }
    category_tag { 'popular_agency' }
  end
end
