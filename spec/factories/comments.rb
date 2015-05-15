# -*- encoding : utf-8 -*-
FactoryGirl.define do

    factory :comment do
        user
        info_request

        body 'This a wise and helpful annotation.'
        comment_type 'request'

        factory :visible_comment do
            visible true
        end

        factory :hidden_comment do
            visible false
        end
    end
    
end
