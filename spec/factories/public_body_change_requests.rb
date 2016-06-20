# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_change_requests
#
#  id                :integer          not null, primary key
#  user_email        :string(255)
#  user_name         :string(255)
#  user_id           :integer
#  public_body_name  :text
#  public_body_id    :integer
#  public_body_email :string(255)
#  source_url        :text
#  notes             :text
#  is_open           :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

FactoryGirl.define do

  factory :public_body_change_request do
    user
    source_url 'http://www.example.com'
    notes 'Please'
    public_body_email 'new@example.com'
    factory :add_body_request do
      public_body_name 'A New Body'
    end
    factory :update_body_request do
      public_body
    end
  end

end
