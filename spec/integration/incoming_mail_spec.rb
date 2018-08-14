# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'when handling incoming mail' do
  let(:info_request){ FactoryBot.create(:info_request) }

  it "receives incoming messages, sends email to requester, and shows them" do
    receive_incoming_mail('incoming-request-plain.email',
                          info_request.incoming_email)
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.to).to eq([info_request.user.email])
    expect(mail.body).to match(/You have a new response to the Freedom of Information request/)
    visit show_request_path :url_title => info_request.url_title
    expect(page).to have_content("No way!")
  end

  it "makes attachments available for download" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          info_request.incoming_email)
    visit get_attachment_path(
      :incoming_message_id => info_request.incoming_messages.first.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'hello world.txt',
      :skip_cache => 1)
    expect(page.response_headers['Content-Type']).to eq("text/plain; charset=utf-8")
    expect(page).to have_content "Second hello"

    visit get_attachment_path(
     :incoming_message_id => info_request.incoming_messages.first.id,
     :id => info_request.id,
     :part => 3,
     :file_name => 'hello world.txt',
     :skip_cache => 1)
    expect(page.response_headers['Content-Type']).to eq("text/plain; charset=utf-8")
    expect(page).to have_content "First hello"
  end

  it "converts message body to UTF8" do
    receive_incoming_mail('iso8859_2_raw_email.email',
                          info_request.incoming_email)
    visit show_request_path :url_title => info_request.url_title
    expect(page).to have_content "tënde"
  end

  it "generates a valid HTML verson of plain text attachments" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          info_request.incoming_email)
    visit get_attachment_as_html_path(
      :incoming_message_id => info_request.incoming_messages.first.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'hello world.txt.html',
      :skip_cache => 1)
    expect(page.response_headers['Content-Type']).to eq("text/html; charset=utf-8")
    expect(page).to have_content "Second hello"
  end

  it "generates a valid HTML verson of PDF attachments" do
    receive_incoming_mail('incoming-request-pdf-attachment.email',
                          info_request.incoming_email)
    visit get_attachment_as_html_path(
      :incoming_message_id => info_request.incoming_messages.first.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'fs 50379341.pdf.html',
      :skip_cache => 1)
    expect(page.response_headers['Content-Type']).to eq("text/html; charset=utf-8")
    expect(page).to have_content "Walberswick Parish Council"
  end

  it "does not cause a reparsing of the raw email, even when the attachment can't be found" do
    receive_incoming_mail('incoming-request-two-same-name.email',
                          info_request.incoming_email)
    incoming_message = info_request.incoming_messages.first
    attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(
                   incoming_message.get_attachments_for_display,
                   2,
                   'hello world.txt')
    expect(attachment.body).to match "Second hello"

    # change the raw_email associated with the message; this should only be
    # reparsed when explicitly asked for
    incoming_message.raw_email.data = incoming_message.raw_email.data.sub("Second", "Third")
    incoming_message.save!
    # asking for an attachment by the wrong filename should result in redirecting
    # back to the incoming message, but shouldn't cause a reparse:
    visit get_attachment_as_html_path(
      :incoming_message_id => incoming_message.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'hello world.txt.baz.html',
      :skip_cache => 1
    )

    attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(
                  incoming_message.get_attachments_for_display,
                  2,
                  'hello world.txt')
    expect(attachment.body).to match "Second hello"

    # ...nor should asking for it by its correct filename...
    visit get_attachment_as_html_path(
      :incoming_message_id => incoming_message.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'hello world.txt.html',
      :skip_cache => 1
    )
    expect(page).not_to have_content "Third hello"

    # ...but if we explicitly ask for attachments to be extracted, then they should be
    force = true
    incoming_message.parse_raw_email!(force)
    attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(
                 incoming_message.get_attachments_for_display,
                 2,
                 'hello world.txt')
    expect(attachment.body).to match "Third hello"
    visit get_attachment_as_html_path(
      :incoming_message_id => incoming_message.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'hello world.txt.html',
      :skip_cache => 1
    )
    expect(page).to have_content "Third hello"
  end

  it "treats attachments with unknown extensions as binary" do
    receive_incoming_mail('incoming-request-attachment-unknown-extension.email',
                          info_request.incoming_email)
    visit get_attachment_path(
      :incoming_message_id => info_request.incoming_messages.first.id,
      :id => info_request.id,
      :part => 2,
      :file_name => 'hello.qwglhm',
      :skip_cache => 1
    )
    expect(page.response_headers['Content-Type']).to eq("application/octet-stream; charset=utf-8")
    expect(page).to have_content "an unusual sort of file"
  end

end
