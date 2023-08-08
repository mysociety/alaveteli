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
    visit show_request_path url_title: info_request.url_title
    expect(page).to have_content("No way!")
  end

  it "makes attachments available for download" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          email_to: info_request.incoming_email)

    attachment_1_path = get_attachment_path(
      incoming_message_id: info_request.incoming_messages.first.id,
      id: info_request.id,
      part: 2,
      file_name: 'hello world.txt',
      skip_cache: 1
    )
    attachment_2_path = get_attachment_path(
      incoming_message_id: info_request.incoming_messages.first.id,
      id: info_request.id,
      part: 3,
      file_name: 'hello world.txt',
      skip_cache: 1
    )

    visit attachment_1_path
    visit attachment_2_path
    perform_enqueued_jobs

    visit attachment_1_path
    expect(page.response_headers['Content-Type']).to eq(
      "text/plain; charset=utf-8"
    )
    expect(page).to have_content "Second hello"

    visit attachment_2_path
    expect(page.response_headers['Content-Type']).to eq(
      "text/plain; charset=utf-8"
    )
    expect(page).to have_content "First hello"
  end

  it "converts message body to UTF8" do
    receive_incoming_mail('iso8859_2_raw_email.email',
                          email_to: info_request.incoming_email)
    visit show_request_path url_title: info_request.url_title
    expect(page).to have_content "tënde"
  end

  it "generates a valid HTML verson of plain text attachments" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          email_to: info_request.incoming_email)
    visit get_attachment_as_html_path(
      incoming_message_id: info_request.incoming_messages.first.id,
      id: info_request.id,
      part: 2,
      file_name: 'hello world.txt.html',
      skip_cache: 1)
    expect(page.response_headers['Content-Type']).to eq("text/html; charset=utf-8")
    expect(page).to have_content "Second hello"
  end

  it "generates a valid HTML verson of PDF attachments" do
    receive_incoming_mail('incoming-request-pdf-attachment.email',
                          email_to: info_request.incoming_email)
    visit get_attachment_as_html_path(
      incoming_message_id: info_request.incoming_messages.first.id,
      id: info_request.id,
      part: 2,
      file_name: 'fs 50379341.pdf.html',
      skip_cache: 1)
    expect(page.response_headers['Content-Type']).to eq("text/html; charset=utf-8")
    expect(page).to have_content "Walberswick Parish Council"
  end

  it "redirects back to incoming message when the attachment can't be found" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          email_to: info_request.incoming_email)
    # asking for an attachment by the wrong filename should result in
    # redirecting back to the incoming message
    visit get_attachment_as_html_path(
      incoming_message_id: info_request.incoming_messages.first.id,
      id: info_request.id,
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
      incoming_message_id: info_request.incoming_messages.first.id,
      id: info_request.id,
      part: 2,
      file_name: 'hello.qwglhm',
      skip_cache: 1
    )

    visit attachment_path
    perform_enqueued_jobs

    visit attachment_path
    expect(page.response_headers['Content-Type']).to eq("application/octet-stream; charset=utf-8")
    expect(page).to have_content "an unusual sort of file"
  end

end
