FactoryGirl.define do

    sequence(:email) { |n| "person#{n}@example.com" }

    factory :foi_attachment do
        factory :body_text do
            content_type 'text/plain'
            body { 'hereisthetext' }
        end
        factory :pdf_attachment do
            content_type 'application/pdf'
            filename 'interesting.pdf'
            body { load_file_fixture('interesting.pdf') }
        end
    end

    factory :incoming_message do
        info_request
        raw_email
        last_parsed { 1.week.ago }
        sent_at { 1.week.ago }
        mail_from 'A Public Body'
        after(:create) do |incoming_message, evaluator|
            FactoryGirl.create(:body_text,
                               incoming_message: incoming_message,
                               url_part_number: 1)
        end
        factory :incoming_message_with_attachments do
            # foi_attachments_count is declared as an ignored attribute and available in
            # attributes on the factory, as well as the callback via the evaluator
            ignore do
                foi_attachments_count 2
            end

            # the after(:create) yields two values; the incoming_message instance itself and the
            # evaluator, which stores all values from the factory, including ignored
            # attributes;
            after(:create) do |incoming_message, evaluator|
                evaluator.foi_attachments_count.times do |count|
                    FactoryGirl.create(:pdf_attachment,
                                       incoming_message: incoming_message,
                                       url_part_number: count+2)
                end
            end
        end
    end

    factory :raw_email

    factory :outgoing_message do
        factory :initial_request do
            status 'ready'
            message_type 'initial_request'
            body 'Some information please'
            what_doing 'normal_sort'
            initialize_with { new(attributes) }
            after(:create) do |outgoing_message|
                outgoing_message.send_message
            end
        end
    end

    factory :info_request do
        title "Example Title"
        public_body
        user

        after(:create) do |info_request, evaluator|
            FactoryGirl.create(:initial_request, info_request: info_request)
        end

        factory :info_request_with_incoming do
            after(:create) do |info_request, evaluator|
                incoming_message = FactoryGirl.create(:incoming_message, info_request: info_request)
                info_request.log_event("response", {:incoming_message_id => incoming_message.id})
            end
        end

        factory :info_request_with_incoming_attachments do
            after(:create) do |info_request, evaluator|
                incoming_message = FactoryGirl.create(:incoming_message_with_attachments, info_request: info_request)
                info_request.log_event("response", {:incoming_message_id => incoming_message.id})
            end
        end

        factory :external_request do
            user nil
            external_user_name 'External User'
            external_url 'http://www.example.org/request/external'
        end

    end

    factory :user do
        name 'Example User'
        email
        salt "-6116981980.392287733335677"
        hashed_password '6b7cd45a5f35fd83febc0452a799530398bfb6e8' # jonespassword
        email_confirmed true
        factory :admin_user do
            name 'Admin User'
            admin_level 'super'
        end
    end

    factory :public_body do
        name 'Example Public Body'
        short_name 'Example Public Body'
        request_email 'request@example.com'
        last_edit_editor "admin user"
        last_edit_comment "Making an edit"
    end

end
