# -*- encoding : utf-8 -*-
FactoryGirl.define do

    factory :holiday do
        day Date.new(2010, 1, 1)
        description "New Year's Day"
    end

end
