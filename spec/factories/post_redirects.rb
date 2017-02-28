# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: post_redirects
#
#  id                 :integer          not null, primary key
#  token              :text             not null
#  uri                :text             not null
#  post_params_yaml   :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  email_token        :text             not null
#  reason_params_yaml :text
#  user_id            :integer
#  circumstance       :text             default("normal"), not null
#

FactoryGirl.define do
  factory :post_redirect do
    user
    uri { frontpage_path }
    reason_params_yaml do
      {
        web: 'To test the post redirect',
        email: 'To test the post redirect'
      }.to_yaml
    end
    post_params_yaml { {}.to_yaml }

    factory :new_request_post_redirect do
      uri '/en/new'
      post_params_yaml do
        public_body = FactoryGirl.create(:public_body)
        {
          "outgoing_message" => {
            "body" => "Dear Ministry of Defence,\r\n\r\nThis is my test\r\n\r\n\r\nYours faithfully,\r\n\r\nSteve Day",
            "what_doing"=>"normal_sort"
          },
          "info_request" => {
            "title" => "Testing the post redirect to pro things",
            "public_body_id" => "#{public_body.id}"
          },
          "submitted_new_request" => "1",
          "preview" => "0",
          "submit" => "Send request",
          "controller" => "request",
          "action" => "new"
        }.to_yaml
      end
    end
  end
end
