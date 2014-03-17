FactoryGirl.define do

    factory :foi_attachment do
        factory :body_text do
            content_type 'text/plain'
            body { 'hereisthetext' }
            filename 'attachment.txt'
        end
        factory :pdf_attachment do
            content_type 'application/pdf'
            filename 'interesting.pdf'
            body { load_file_fixture('interesting.pdf') }
        end
        factory :rtf_attachment do
            content_type 'application/rtf'
            filename 'interesting.rtf'
            body { load_file_fixture('interesting.rtf') }
        end
    end

end
