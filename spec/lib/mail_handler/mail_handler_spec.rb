# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

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
        mail_data = load_file_fixture('incoming-request-plain.email')
        mail_data.gsub!('EMAIL_FROM', '')
        mail = MailHandler.mail_from_raw_email(mail_data)
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
        mail_data = load_file_fixture('incoming-request-plain.email')
        mail_data.gsub!('EMAIL_FROM', '')
        mail = MailHandler.mail_from_raw_email(mail_data)
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
