FactoryBot.define do

  factory :foi_attachment do
    sequence(:url_part_number) { |n| n + 1 }
    display_size { '0K' }
    masked_at { 1.day.ago }

    transient do
      body { 'hereisthemaskedtext' }
    end

    after(:build) do |foi_attachment, evaluator|
      body = evaluator.body
      foi_attachment.hexdigest = Digest::MD5.hexdigest(body) if body

      next unless body && foi_attachment.filename && foi_attachment.content_type

      foi_attachment.file.attach(
        io: StringIO.new(body),
        filename: foi_attachment.filename,
        content_type: foi_attachment.content_type
      )
    end

    trait :unmasked do
      masked_at { nil }
    end

    factory :body_text do
      content_type { 'text/plain' }
      body { 'hereisthetext' }
      filename { 'attachment.txt' }
    end
    factory :pdf_attachment do
      content_type { 'application/pdf' }
      filename { 'interesting.pdf' }
      body { load_file_fixture('interesting.pdf') }
    end
    factory :rtf_attachment do
      content_type { 'application/rtf' }
      filename { 'interesting.rtf' }
      body { load_file_fixture('interesting.rtf') }
    end
    factory :html_attachment do
      content_type { 'text/html' }
      filename { 'interesting.html' }
      body {
        # Needed to force HTML attachment into CRLF line endings due to an issue
        # with the mail gem which results in a different hexdigest after
        # rebuilding the raw emails.
        # Once https://github.com/mikel/mail/pull/1512 is merged we can revert
        # the FoiAttachment factory change.
        Mail::Utilities.to_crlf(load_file_fixture('interesting.html'))
      }
    end
    factory :jpeg_attachment do
      content_type { 'image/jpeg' }
      filename { 'interesting.jpg' }
      body { 'someimage' }
    end
    factory :unknown_attachment do
      content_type { 'application/unknown' }
      filename { 'interesting.spc' }
      body { 'something' }
    end
  end

end
