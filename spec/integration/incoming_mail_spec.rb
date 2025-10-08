require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'when handling incoming mail' do
  include ActiveJob::TestHelper

  let(:info_request) { FactoryBot.create(:info_request) }

  it "receives incoming messages, sends email to requester, and shows them" do
    receive_incoming_mail('incoming-request-plain.email',
                          email_to: info_request.incoming_email)
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.to).to eq([info_request.user.email])
    expect(mail.body).to match(/You have a new response to the Freedom of Information request/)
    visit show_request_path info_request.url_title
    expect(page).to have_content("No way!")
  end

  it "makes attachments available for download" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          email_to: info_request.incoming_email)

    attachment_1_path = get_attachment_path(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 2,
      file_name: 'hello world.txt',
      skip_cache: 1
    )
    attachment_2_path = get_attachment_path(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 3,
      file_name: 'hello world.txt',
      skip_cache: 1
    )

    visit attachment_1_path
    visit attachment_2_path
    perform_enqueued_jobs

    visit attachment_1_path
    expect(page.response_headers['Content-Type']).to eq("text/plain")
    expect(page).to have_content "Second hello"

    visit attachment_2_path
    expect(page.response_headers['Content-Type']).to eq("text/plain")
    expect(page).to have_content "First hello"
  end

  it "converts message body to UTF8" do
    receive_incoming_mail('iso8859_2_raw_email.email',
                          email_to: info_request.incoming_email)
    visit show_request_path(info_request.url_title)
    expect(page).to have_content "tënde"
  end

  it "generates a valid HTML version of plain text attachments" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          email_to: info_request.incoming_email)
    attachment_path = get_attachment_as_html_path(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 2,
      file_name: 'hello world.txt.html',
      skip_cache: 1)

    visit attachment_path
    perform_enqueued_jobs

    visit attachment_path
    expect(page.response_headers['Content-Type']).to eq("text/html; charset=utf-8")
    expect(page).to have_content "Second hello"
  end

  it "generates a valid HTML version of PDF attachments" do
    receive_incoming_mail('incoming-request-pdf-attachment.email',
                          email_to: info_request.incoming_email)
    attachment_as_html_path = get_attachment_as_html_path(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 2,
      file_name: 'fs 50379341.pdf.html',
      skip_cache: 1)

    attachment_url = get_attachment_url(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 2,
      file_name: 'fs 50379341.pdf',
      cookie_passthrough: 1
    )

    visit attachment_as_html_path
    perform_enqueued_jobs

    visit attachment_as_html_path
    expect(page.response_headers['Content-Type']).to eq("text/html; charset=utf-8")
    expect(page).to have_element('iframe', src: attachment_url)
  end

  it "redirects back to incoming message when the attachment can't be found" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          email_to: info_request.incoming_email)
    # asking for an attachment by the wrong filename should result in
    # redirecting back to the incoming message
    visit get_attachment_as_html_path(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 2,
      file_name: 'hello world.txt.baz.html',
      skip_cache: 1
    )

    expect(current_path).to eq(show_request_path(info_request.url_title))
  end

  it "treats attachments with unknown extensions as binary" do
    receive_incoming_mail('incoming-request-attachment-unknown-extension.email',
                          email_to: info_request.incoming_email)

    attachment_path = get_attachment_path(
      info_request.url_title,
      incoming_message_id: info_request.incoming_messages.first.id,
      part: 2,
      file_name: 'hello.qwglhm',
      skip_cache: 1
    )

    visit attachment_path
    perform_enqueued_jobs

    visit attachment_path
    expect(page.response_headers['Content-Type']).to eq("application/octet-stream")
    expect(page).to have_content "an unusual sort of file"
  end

  it "does not automatically extract attachments after receiving email" do
    receive_incoming_mail('incoming-request-plain.email',
                          email_to: info_request.incoming_email)
    perform_enqueued_jobs

    im = info_request.incoming_messages.first
    expect(im.foi_attachments).to be_empty
  end

  it "extract attachments when inbound email contains an Excel spreadsheet" do
    mail = Mail.new(to: info_request.incoming_email) do
      body 'My excel spreadsheet'
      add_file 'gems/excel_analyzer/spec/fixtures/data.xlsx'
    end

    receive_incoming_mail(mail.to_s)
    perform_enqueued_jobs

    im = info_request.incoming_messages.first
    expect(im.foi_attachments).to_not be_empty
  end
end
