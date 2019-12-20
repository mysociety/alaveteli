# -*- encoding : utf-8 -*-
FactoryBot.define do

  factory :foi_attachment do
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
      body { load_file_fixture('interesting.html') }
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
