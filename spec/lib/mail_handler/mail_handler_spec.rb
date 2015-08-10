# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

def create_message_from(from_field)
  mail_data = load_file_fixture('incoming-request-plain.email')
  mail_data.gsub!('EMAIL_FROM', from_field)
  mail = MailHandler.mail_from_raw_email(mail_data)
end

describe 'when creating a mail object from raw data' do

  it "should be able to parse a large email without raising an exception" do
    m = Mail.new
    m.add_file(:filename => "attachment.data", :content => "a" * (8 * 1024 * 1024))
    raw_email = "From jamis_buck@byu.edu Mon May  2 16:07:05 2005\r\n#{m.to_s}"
    expect { Mail::Message.new(raw_email) }.not_to raise_error
  end

  it 'should correctly parse a multipart email with a linebreak in the boundary' do
    mail = get_fixture_mail('space-boundary.email')
    expect(mail.parts.size).to eq(2)
    expect(mail.multipart?).to eq(true)
  end

  it "should not fail on invalid byte sequence in content-disposition header" do
    part = Mail::Part.new("Content-Disposition: inline; filename=a\xB8z\r\n\r\nThis is the body text.")
    expect { part.inline? }.not_to raise_error
  end

  it 'should parse multiple to addresses with unqoted display names' do
    mail = get_fixture_mail('multiple-unquoted-display-names.email')
    expect(mail.to).to eq(["request-66666-caa77777@whatdotheyknow.com", "foi@example.com"])
  end

  it 'should return nil for malformed To: and Cc: lines' do
    mail = get_fixture_mail('malformed-to-and-cc.email')
    expect(mail.to).to eq(nil)
    expect(mail.cc).to eq(nil)
  end

  it 'should convert an iso8859 email to utf8' do
    mail = get_fixture_mail('iso8859_2_raw_email.email')
    expect(mail.subject).to match /gjatë/u
    expect(MailHandler.get_part_body(mail).is_utf8?).to eq(true)
  end

  it 'should not be confused by subject lines with malformed UTF-8 at the end' do
    # The base64 subject line was generated with:
    #   printf "hello\360" | base64
    # ... and wrapping the result in '=?UTF-8?B?' and '?='
    mail = get_fixture_mail('subject-bad-utf-8-trailing-base64.email')
    expect(mail.subject).to eq('hello')
    # The quoted printable subject line was generated with:
    #   printf "hello\360" | qprint -b -e
    # ... and wrapping the result in '=?UTF-8?Q?' and '?='
    mail = get_fixture_mail('subject-bad-utf-8-trailing-quoted-printable.email')
    expect(mail.subject).to eq('hello')
  end

  it 'should convert a Windows-1252 body mislabelled as ISO-8859-1 to UTF-8' do
    mail = get_fixture_mail('mislabelled-as-iso-8859-1.email')
    body = MailHandler.get_part_body(mail)
    expect(body.is_utf8?).to eq(true)
    # This email is broken in at least these two ways:
    #  1. It contains a top bit set character (0x96) despite the
    #     "Content-Transfer-Encoding: 7bit"
    #  2. The charset in the Content-Type header is "iso-8859-1"
    #     but 0x96 is actually a Windows-1252 en dash, which would
    #     be Unicode codepoint 2013.  It should be possible to
    #     spot the mislabelling, since 0x96 isn't a valid
    #     ISO-8859-1 character.
    expect(body).to match(/ \xe2\x80\x93 /)
  end

  it 'should not error on a subject line with an encoding encoding not recognized by iconv' do
    mail = get_fixture_mail('unrecognized-encoding-mail.email')
    expect{ mail.subject }.not_to raise_error
  end

end

describe 'when asked for the from name' do

  it 'should return nil if there is a blank "From" field' do
    mail = create_message_from('')
    expect(MailHandler.get_from_name(mail)).to eq(nil)
  end

  it 'should correctly return an encoded name from the from field' do
    mail = get_fixture_mail('quoted-subject-iso8859-1.email')
    expect(MailHandler.get_from_name(mail)).to eq('Coordenação de Relacionamento, Pesquisa e Informação/CEDI')
  end

  it 'should get a name from a "From" field with a name and address' do
    mail = get_fixture_mail('incoming-request-oft-attachments.email')
    expect(MailHandler.get_from_name(mail)).to eq('Public Authority')
  end

  it 'should return nil from a "From" field that is just a name'do
    mail = get_fixture_mail('track-response-webshield-bounce.email')
    expect(MailHandler.get_from_name(mail)).to eq(nil)
  end

end

describe 'when asked for the from address' do

  it 'should return nil if there is a blank "From" field' do
    mail = create_message_from('')
    expect(MailHandler.get_from_address(mail)).to eq(nil)
  end

  it 'should correctly return an address from a mail that has an encoded name in the from field' do
    mail = get_fixture_mail('quoted-subject-iso8859-1.email')
    expect(MailHandler.get_from_address(mail)).to eq('geraldinequango@localhost')
  end

  it 'should return nil if there is no address in the "From" field' do
    mail = get_fixture_mail('track-response-webshield-bounce.email')
    expect(MailHandler.get_from_address(mail)).to eq(nil)
  end

  it 'should return the "From" email address if there is one' do
    mail = get_fixture_mail('track-response-abcmail-oof.email')
    expect(MailHandler.get_from_address(mail)).to eq('Name.Removed@example.gov.uk')
  end

  it 'should get an address from a "From" field with a name and address' do
    mail = get_fixture_mail('incoming-request-oft-attachments.email')
    expect(MailHandler.get_from_address(mail)).to eq('public@authority.gov.uk')
  end
end

describe 'when asked for all the addresses a mail has been sent to' do

  it 'should return an array containing the envelope-to address and the to address, and the cc address if there is one' do
    mail_data = load_file_fixture('humberside-police-odd-mime-type.email')
    mail_data.gsub!('Envelope-to: request-5335-xxxxxxxx@whatdotheyknow.com',
                    'Envelope-to: request-5555-xxxxxxxx@whatdotheyknow.com')
    mail_data.gsub!('Cc: request-5335-xxxxxxxx@whatdotheyknow.com',
                    'Cc: request-3333-xxxxxxxx@whatdotheyknow.com')
    mail = MailHandler.mail_from_raw_email(mail_data)
    expect(MailHandler.get_all_addresses(mail)).to eq(['request-5335-xxxxxxxx@whatdotheyknow.com',
                                                   'request-3333-xxxxxxxx@whatdotheyknow.com',
                                                   'request-5555-xxxxxxxx@whatdotheyknow.com'])
  end

  it 'should only return unique values' do
    # envelope-to and to fields are the same
    mail = get_fixture_mail('humberside-police-odd-mime-type.email')
    expect(MailHandler.get_all_addresses(mail)).to eq(['request-5335-xxxxxxxx@whatdotheyknow.com'])
  end

  it 'should handle the absence of an envelope-to or cc field' do
    mail_data = load_file_fixture('autoresponse-header.email')
    mail_data.gsub!('To: FOI Person <EMAIL_TO>',
                    'To: FOI Person <request-5555-xxxxxxxx@whatdotheyknow.com>')
    mail = MailHandler.mail_from_raw_email(mail_data)
    expect(MailHandler.get_all_addresses(mail)).to eq(["request-5555-xxxxxxxx@whatdotheyknow.com"])
  end

  it 'should not return invalid addresses' do
    mail_data = load_file_fixture('autoresponse-header.email')
    mail_data.gsub!('To: FOI Person <EMAIL_TO>',
                    'To: <request-5555-xxxxxxxx>')
    mail = MailHandler.mail_from_raw_email(mail_data)
    expect(MailHandler.get_all_addresses(mail)).to eq([])
  end


end

describe 'when asked for auto_submitted' do

  it 'should return a string value for an email with an auto-submitted header' do
    mail = get_fixture_mail('autoresponse-header.email')
    expect(MailHandler.get_auto_submitted(mail)).to eq('auto-replied')
  end

  it 'should return a nil value for an email with no auto-submitted header' do
    mail = get_fixture_mail('incoming-request-plain.email')
    expect(MailHandler.get_auto_submitted(mail)).to eq(nil)
  end

end

describe 'when asked if there is an empty return path' do

  it 'should return true if there is an empty return-path specified' do
    mail = get_fixture_mail('empty-return-path.email')
    expect(MailHandler.empty_return_path?(mail)).to eq(true)
  end

  it 'should return false if there is no return-path header' do
    mail = get_fixture_mail('incoming-request-attach-attachments.email')
    expect(MailHandler.empty_return_path?(mail)).to eq(false)
  end

  it 'should return false if there is a return path address' do
    mail = get_fixture_mail('autoresponse-header.email')
    expect(MailHandler.empty_return_path?(mail)).to eq(false)
  end
end

describe 'when deriving a name, email and formatted address from a message from a line' do

  def should_render_from_address(from_line, expected_result)
    mail = create_message_from(from_line)
    name = MailHandler.get_from_name(mail)
    email = MailHandler.get_from_address(mail)
    address = MailHandler.address_from_name_and_email(name, email).to_s
    expect([name, email, address]).to eq(expected_result)
  end

  it 'should correctly render a name with quoted commas' do
    should_render_from_address('"Clare College, Cambridge" <test@test.test>',
                               ['Clare College, Cambridge',
                                'test@test.test',
                                '"Clare College, Cambridge" <test@test.test>'])
  end

  it 'should correctly reproduce a simple name and email that does not need quotes' do
    should_render_from_address('"FOI Person" <foiperson@localhost>',
                               ['FOI Person',
                                'foiperson@localhost',
                                'FOI Person <foiperson@localhost>'])
  end

  it 'should render an address with no name' do
    should_render_from_address("foiperson@localhost",
                               [nil,
                                "foiperson@localhost",
                                "foiperson@localhost"])
  end

  it 'should quote a name with a square bracked in it' do
    should_render_from_address('"FOI [ Person" <foiperson@localhost>',
                               ['FOI [ Person',
                                'foiperson@localhost',
                                '"FOI [ Person" <foiperson@localhost>'])
  end

  it 'should quote a name with an @ in it' do
    should_render_from_address('"FOI @ Person" <foiperson@localhost>',
                               ['FOI @ Person',
                                'foiperson@localhost',
                                '"FOI @ Person" <foiperson@localhost>'])
  end


  it 'should quote a name with quotes in it' do
    should_render_from_address('"FOI \" Person" <foiperson@localhost>',
                               ['FOI " Person',
                                'foiperson@localhost',
                                '"FOI \" Person" <foiperson@localhost>'])
  end

end

describe 'when getting the content type of a mail part' do

  def expect_content_type(fixture_file, content_type)
    mail = get_fixture_mail(fixture_file)
    expect(MailHandler.get_content_type(mail)).to eq(content_type)
  end

  it 'should correctly return a type of "multipart/report"' do
    expect_content_type('track-response-multipart-report.email', 'multipart/report')
  end

  it 'should correctly return a type of "text/plain"' do
    expect_content_type('track-response-abcmail-oof.email', 'text/plain')
  end

  it 'should correctly return a type of "multipart/mixed"' do
    expect_content_type('track-response-messageclass-oof.email', 'multipart/mixed')
  end

  it 'should correctly return the types in an example bounce report' do
    mail = get_fixture_mail('track-response-ms-bounce.email')
    report = mail.parts.detect{ |part| MailHandler.get_content_type(part) == 'multipart/report'}
    expect(MailHandler.get_content_type(report.parts[0])).to eq('text/plain')
    expect(MailHandler.get_content_type(report.parts[1])).to eq('message/delivery-status')
    expect(MailHandler.get_content_type(report.parts[2])).to eq('message/rfc822')
  end

end

describe 'when getting header strings' do

  def expect_header_string(fixture_file, header, header_string)
    mail = get_fixture_mail(fixture_file)
    expect(MailHandler.get_header_string(header, mail)).to eq(header_string)
  end

  it 'should return the contents of a "Subject" header' do
    expect_header_string('track-response-ms-bounce.email',
                         'Subject',
                         'Delivery Status Notification (Delay)')
  end

  it 'should return the contents of an "X-Failed-Recipients" header' do
    expect_header_string('autoresponse-header.email',
                         'X-Failed-Recipients',
                         'enquiries@cheese.com')
  end

  it 'should return the contents of an example "" header' do
    expect_header_string('track-response-messageclass-oof.email',
                         'X-POST-MessageClass',
                         '9; Autoresponder')
  end

end

describe "when parsing HTML mail" do
  it "should display UTF-8 characters in the plain text version correctly" do
    html = "<html><b>foo</b> është"
    plain_text = MailHandler.get_attachment_text_one_file('text/html', html)
    expect(plain_text).to match(/është/)
  end

end

describe "when getting the attachment text" do
  it "should not raise an error if the expansion of a zip file raises an error" do
    mock_entry = double('ZipFile entry', :file? => true)
    mock_entries = [mock_entry]
    allow(mock_entries).to receive(:close)
    allow(mock_entry).to receive(:get_input_stream).and_raise("invalid distance too far back")
    allow(Zip::ZipFile).to receive(:open).and_return(mock_entries)
    MailHandler.get_attachment_text_one_file('application/zip', "some string")
  end

end

describe 'when getting attachment attributes' do

  it 'should handle a mail with a non-multipart part with no charset in the Content-Type header' do
    mail = get_fixture_mail('part-without-charset-in-content-type.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.size).to eq(2)
  end

  it 'should get two attachment parts from a multipart mail with text and html alternatives
    and an image' do
    mail = get_fixture_mail('quoted-subject-iso8859-1.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.size).to eq(2)
  end

  it 'should get one attachment from a multipart mail with text and HTML alternatives, which should be UTF-8' do
    mail = get_fixture_mail('iso8859_2_raw_email.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.length).to eq(1)
    expect(attributes[0][:body].is_utf8?).to eq(true)
  end

  it 'should get multiple attachments from a multipart mail with text and HTML alternatives, which should be UTF-8' do
    mail = get_fixture_mail('apple-mail-with-attachments.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.length).to eq(7)
  end

  it 'should expand a mail attached as text' do
    # Note that this spec will only pass using Tmail in the timezone set as datetime headers
    # are rendered out in the local time - using the Mail gem this is not necessary
    with_env_tz('London') do
      mail = get_fixture_mail('rfc822-attachment.email')
      attributes = MailHandler.get_attachment_attributes(mail)
      expect(attributes.size).to eq(2)
      rfc_attachment = attributes[1]
      expect(rfc_attachment[:within_rfc822_subject]).to eq('Freedom of Information request')
      headers = ['Date: Thu, 13 Mar 2008 16:57:33 +0000',
                 'Subject: Freedom of Information request',
                 'From: An FOI Officer <foi.officer@example.com>',
                 'To: request-bounce-xx-xxxxx@whatdotheyno.com']
      expect(rfc_attachment[:body]).to eq("#{headers.join("\n")}\n\nsome example text")
    end
  end

  it 'should handle a mail which causes Tmail to generate a blank header value' do
    mail = get_fixture_mail('many-attachments-date-header.email')
    attributes = MailHandler.get_attachment_attributes(mail)
  end

  it 'should ignore truncated TNEF attachment' do
    mail = get_fixture_mail('tnef-attachment-truncated.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.length).to eq(2)
  end

  it 'should ignore anything beyond the final MIME boundary' do
    skip do
      # This example raw email has a premature closing boundary for
      # the outer multipart/mixed - my reading of RFC 1521 is that
      # the "epilogue" beyond that should be ignored.
      # See https://github.com/mysociety/alaveteli/issues/922 for
      # more discussion.
      mail = get_fixture_mail('nested-attachments-premature-end.email')
      attributes = MailHandler.get_attachment_attributes(mail)
      attributes.length.should == 3
    end
  end

  it 'should cope with a missing final MIME boundary' do
    mail = get_fixture_mail('multipart-no-final-boundary.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.length).to eq(1)
    expect(attributes[0][:body]).to match(/This is an acknowledgement of your email/)
    expect(attributes[0][:content_type]).to eq("text/plain")
    expect(attributes[0][:url_part_number]).to eq(1)
  end

  it 'should ignore a TNEF attachment with no usable contents' do
    # FIXME: "no usable contents" is slightly misleading.  The
    # attachment in this example email does have usable content in
    # the body of the TNEF attachment, but the invocation of tnef
    # historically used to unpack these attachments doesn't add
    # the --save-body parameter, so that they have been ignored so
    # far.  We probably should include the body from such
    # attachments, but, at the moment, with the pending upgrade to
    # Rails 3, we just want to check that the behaviour is the
    # same as before.
    mail = get_fixture_mail('tnef-attachment-empty.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes.length).to eq(2)
    # This is the size of the TNEF-encoded attachment; currently,
    # we expect the code just to return this without decoding:
    expect(attributes[1][:body].length).to eq(7769)
  end

  it 'should treat a document/pdf attachment as application/pdf' do
    mail = get_fixture_mail('document-pdf.email')
    attributes = MailHandler.get_attachment_attributes(mail)
    expect(attributes[1][:content_type]).to eq("application/pdf")
  end

  it 'should produce a consistent set of url_part_numbers, content_types, within_rfc822_subjects
        and filenames from an example mail with lots of attachments' do
    mail = get_fixture_mail('many-attachments-date-header.email')
    attributes = MailHandler.get_attachment_attributes(mail)

    expected_attributes = [ { :content_type=>"text/plain",
                              :url_part_number=>1,
                              :within_rfc822_subject=>nil,
                              :filename=>nil},
                            { :content_type=>"text/plain",
                              :url_part_number=>2,
                              :within_rfc822_subject=>"Re: xxx",
                              :filename=>nil},
                            { :content_type=>"text/html",
                              :url_part_number=>4,
                              :within_rfc822_subject=>"example",
                              :filename=>nil},
                            { :content_type=>"image/gif", :url_part_number=>5,
                              :within_rfc822_subject=>"example",
                              :filename=>"image001.gif"},
                            { :content_type=>"application/vnd.ms-excel",
                              :url_part_number=>6,
                              :within_rfc822_subject=>"example",
                              :filename=>"particpant list.xls"},
                            { :content_type=>"text/plain",
                              :url_part_number=>7,
                              :within_rfc822_subject=>"RE: example",
                              :filename=>nil},
                            { :content_type=>"text/html",
                              :url_part_number=>9,
                              :within_rfc822_subject=>"As promised - Masterclass info (example)",
                              :filename=>nil},
                            { :content_type=>"image/gif",
                              :url_part_number=>10,
                              :within_rfc822_subject=>"As promised - Masterclass info (example)",
                              :filename=>"image001.gif"},
                            { :content_type=>"application/vnd.ms-word",
                              :url_part_number=>11,
                              :within_rfc822_subject=>"As promised - Masterclass info (example)",
                              :filename=>"Participant List.doc"},
                            { :content_type=>"application/vnd.ms-word",
                              :url_part_number=>12,
                              :within_rfc822_subject=>"As promised - Masterclass info (example)",
                              :filename=>"Information & Booking Form.doc"},
                            { :content_type=>"text/plain",
                              :url_part_number=>13,
                              :within_rfc822_subject=>"Re: As promised - info (example)",
                              :filename=>nil},
                            { :content_type=>"text/html",
                              :url_part_number=>15,
                              :within_rfc822_subject=>"Thank you from example",
                              :filename=>nil},
                            { :content_type=>"image/gif",
                              :url_part_number=>16,
                              :within_rfc822_subject=>"Thank you from example",
                              :filename=>"image001.gif"},
                            { :content_type=>"text/plain",
                              :url_part_number=>17,
                              :within_rfc822_subject=>"example - Meeting - Tuesday 2nd March",
                              :filename=>nil},
                            { :content_type=>"text/plain",
                              :url_part_number=>18,
                              :within_rfc822_subject=>"example - Help needed",
                              :filename=>nil},
                            { :content_type=>"application/pdf",
                              :url_part_number=>19,
                              :within_rfc822_subject=>"example - Help needed",
                              :filename=>"Information Pack.pdf"},
                            { :content_type=>"text/plain",
                              :url_part_number=>20,
                              :within_rfc822_subject=>"Re: As promised - info (example)",
                              :filename=>nil} ]

    attributes.each_with_index do |attr, index|
      attr.delete(:charset)
      attr.delete(:body)
      attr.delete(:hexdigest)
      expect(attr).to eq(expected_attributes[index])
    end
  end
end

describe 'when getting the address part from an address string' do

  it 'should handle non-ascii characters in the name input' do
    address = "\"Someone’s name\" <test@example.com>"
    expect(MailHandler.address_from_string(address)).to eq('test@example.com')
  end
end
