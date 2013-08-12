FactoryGirl.define do

    factory :incoming_message do
        info_request
        raw_email
    end

    factory :raw_email

    factory :info_request do
        title "Example Title"
        public_body
        user
    end

    factory :user do
        name 'Example User'
        email 'user@example.com'
        salt "-6116981980.392287733335677"
        hashed_password '6b7cd45a5f35fd83febc0452a799530398bfb6e8' # jonespassword
    end

    factory :public_body do
        name 'Example Public Body'
        short_name 'Example Public Body'
        request_email 'request@example.com'
        last_edit_editor "admin user"
        last_edit_comment "Making an edit"
    end

end
