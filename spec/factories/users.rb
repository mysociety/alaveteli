# -*- encoding : utf-8 -*-
FactoryGirl.define do

    factory :user do
        name 'Example User'
        sequence(:email) { |n| "person#{n}@example.com" }
        salt "-6116981980.392287733335677"
        hashed_password '6b7cd45a5f35fd83febc0452a799530398bfb6e8' # jonespassword
        email_confirmed true
        ban_text ""
        factory :admin_user do
            name 'Admin User'
            admin_level 'super'
        end
    end

end
