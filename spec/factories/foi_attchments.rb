FactoryGirl.define do

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

end
