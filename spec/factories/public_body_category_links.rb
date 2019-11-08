# == Schema Information
# Schema version: 20220322100510
#
# Table name: public_body_category_links
#
#  public_body_category_id :bigint           not null
#  public_body_heading_id  :bigint           not null
#  category_display_order  :bigint
#  id                      :bigint           not null, primary key
#  created_at              :datetime
#  updated_at              :datetime
#

FactoryBot.define do
  factory :public_body_category_link do
    association :public_body_category
    association :public_body_heading
  end
end
