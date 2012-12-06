# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

def create_message_from(from_field)
    mail_data = load_file_fixture('incoming-request-plain.email')
    mail_data.gsub!('EMAIL_FROM', from_field)
    mail = MailHandler.mail_from_raw_email(mail_data)
end

describe 'when creating a mail object from raw data' do

    it 'should correctly parse a multipart email with a linebreak in the boundary' do
        mail = get_fixture_mail('space-boundary.email')
        mail.parts.size.should == 2
        mail.multipart?.should == true
    end

    it 'should parse multiple to addresses with unqoted display names' do
        mail = get_fixture_mail('multiple-unquoted-display-names.email')
        mail.to.should == ["request-66666-caa77777@whatdotheyknow.com", "foi@example.com"]
    end

    it 'should convert an iso8859 email to utf8' do
        mail = get_fixture_mail('iso8859_2_raw_email.email')
        mail.subject.should have_text(/gjatë/u)
        MailHandler.get_part_body(mail).is_utf8?.should == true
    end

end

describe 'when asked for the from name' do

    it 'should return nil if there is a blank "From" field' do
        mail = create_message_from('')
        MailHandler.get_from_name(mail).should == nil
    end

    it 'should correctly return an encoded name from the from field' do
        mail = get_fixture_mail('quoted-subject-iso8859-1.email')
        MailHandler.get_from_name(mail).should == 'Coordenação de Relacionamento, Pesquisa e Informação/CEDI'
    end

    it 'should get a name from a "From" field with a name and address' do
        mail = get_fixture_mail('incoming-request-oft-attachments.email')
        MailHandler.get_from_name(mail).should == 'Public Authority'
    end

    it 'should return nil from a "From" field that is just a name'do
        mail = get_fixture_mail('track-response-webshield-bounce.email')
        MailHandler.get_from_name(mail).should == nil
    end

end

describe 'when asked for the from address' do

    it 'should return nil if there is a blank "From" field' do
        mail = create_message_from('')
        MailHandler.get_from_address(mail).should == nil
    end

    it 'should correctly return an address from a mail that has an encoded name in the from field' do
        mail = get_fixture_mail('quoted-subject-iso8859-1.email')
        MailHandler.get_from_address(mail).should == 'geraldinequango@localhost'
    end

    it 'should return nil if there is no address in the "From" field' do
        mail = get_fixture_mail('track-response-webshield-bounce.email')
        MailHandler.get_from_address(mail).should == nil
    end

    it 'should return the "From" email address if there is one' do
         mail = get_fixture_mail('track-response-abcmail-oof.email')
        MailHandler.get_from_address(mail).should == 'Name.Removed@example.gov.uk'
    end

    it 'should get an address from a "From" field with a name and address' do
        mail = get_fixture_mail('incoming-request-oft-attachments.email')
        MailHandler.get_from_address(mail).should == 'public@authority.gov.uk'
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
        MailHandler.get_all_addresses(mail).should == ['request-5335-xxxxxxxx@whatdotheyknow.com',
                                                       'request-3333-xxxxxxxx@whatdotheyknow.com',
                                                       'request-5555-xxxxxxxx@whatdotheyknow.com']
    end

    it 'should only return unique values' do
        # envelope-to and to fields are the same
        mail = get_fixture_mail('humberside-police-odd-mime-type.email')
        MailHandler.get_all_addresses(mail).should == ['request-5335-xxxxxxxx@whatdotheyknow.com']
    end

    it 'should handle the absence of an envelope-to or cc field' do
        mail_data = load_file_fixture('autoresponse-header.email')
        mail_data.gsub!('To: FOI Person <EMAIL_TO>',
                        'To: FOI Person <request-5555-xxxxxxxx@whatdotheyknow.com>')
        mail = MailHandler.mail_from_raw_email(mail_data)
        MailHandler.get_all_addresses(mail).should == ["request-5555-xxxxxxxx@whatdotheyknow.com"]
    end
end

describe 'when asked for auto_submitted' do

    it 'should return a string value for an email with an auto-submitted header' do
        mail = get_fixture_mail('autoresponse-header.email')
        MailHandler.get_auto_submitted(mail).should == 'auto-replied'
    end

    it 'should return a nil value for an email with no auto-submitted header' do
        mail = get_fixture_mail('incoming-request-plain.email')
        MailHandler.get_auto_submitted(mail).should == nil
    end

end

describe 'when asked if there is an empty return path' do

    it 'should return true if there is an empty return-path specified' do
        mail = get_fixture_mail('empty-return-path.email')
        MailHandler.empty_return_path?(mail).should == true
    end

    it 'should return false if there is no return-path header' do
        mail = get_fixture_mail('incoming-request-attach-attachments.email')
        MailHandler.empty_return_path?(mail).should == false
    end

    it 'should return false if there is a return path address' do
        mail = get_fixture_mail('autoresponse-header.email')
        MailHandler.empty_return_path?(mail).should == false
    end
end

describe 'when deriving a name, email and formatted address from a message from a line' do

    def should_render_from_address(from_line, expected_result)
        mail = create_message_from(from_line)
        name = MailHandler.get_from_name(mail)
        email = MailHandler.get_from_address(mail)
        address = MailHandler.address_from_name_and_email(name, email).to_s
        [name, email, address].should == expected_result
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
        MailHandler.get_content_type(mail).should == content_type
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
        MailHandler.get_content_type(report.parts[0]).should == 'text/plain'
        MailHandler.get_content_type(report.parts[1]).should == 'message/delivery-status'
        MailHandler.get_content_type(report.parts[2]).should == 'message/rfc822'
    end

end

describe 'when getting header strings' do

    def expect_header_string(fixture_file, header, header_string)
        mail = get_fixture_mail(fixture_file)
        MailHandler.get_header_string(header, mail).should == header_string
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
        plain_text.should match(/është/)
    end

end

describe "when getting the attachment text" do
  it "should not raise an error if the expansion of a zip file raises an error" do
    mock_entry = mock('ZipFile entry', :file? => true)
    mock_entries = [mock_entry]
    mock_entries.stub!(:close)
    mock_entry.stub!(:get_input_stream).and_raise("invalid distance too far back")
    Zip::ZipFile.stub!(:open).and_return(mock_entries)
    MailHandler.get_attachment_text_one_file('application/zip', "some string")
  end

end

describe 'when getting attachment attributes' do

    it 'should handle a mail which causes Tmail to generate a blank header value' do
        mail = get_fixture_mail('many-attachments-date-header.email')
        attributes = MailHandler.get_attachment_attributes(mail)
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
            attr.should == expected_attributes[index]
        end
    end
end
