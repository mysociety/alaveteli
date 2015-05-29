# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '../../../../spec_helper')

describe MailHandler::Backends::MailBackend do
    include MailHandler
    include MailHandler::Backends::MailBackend

    describe :backend do

        it 'should return the name of the backend' do
            backend.should == 'Mail'
        end

    end

    describe :mail_from_raw_email do

        it 'returns a new mail instance of the email' do
            raw_mail = load_file_fixture('raw_emails/1.email')
            expected = Mail.read_from_string(raw_mail)
            mail_from_raw_email(raw_mail).should == expected
        end

    end

    describe :get_part_file_name do

        it 'returns the part file name' do
            mail = get_fixture_mail('document-pdf.email')
            part = mail.attachments.first
            get_part_file_name(part).should == 'tiny-example.pdf'
        end

        it 'returns nil if there is no file name' do
            mail = get_fixture_mail('document-pdf.email')
            part = mail.parts.first
            get_part_file_name(part).should be_nil
        end

        it 'turns an invalid UTF-8 name into a valid one' do
            mail = get_fixture_mail('non-utf8-filename.email')
            part = mail.attachments.first
            filename = get_part_file_name(part)
            if filename.respond_to?(:valid_encoding)
               filename.valid_encoding?.should == true
            end
        end

    end

    describe :get_part_body do

        it 'returns the body of a part' do
            expected = <<-DOC
Here's a PDF attachement which has a document/pdf content-type,
when it really should be application/pdf.\n
DOC
            mail = get_fixture_mail('document-pdf.email')
            part = mail.parts.first
            get_part_body(part).should == expected
        end

    end

    describe :first_from do

        it 'finds the first from field' do
            mail = get_fixture_mail('raw_emails/1.email')
            expected = Mail::Address.new('FOI Person <foiperson@localhost>').to_s
            first_from(mail).to_s.should == expected
        end

    end

    describe :get_from_address do

        it 'finds the first address' do
            mail = get_fixture_mail('raw_emails/1.email')
            get_from_address(mail).should == 'foiperson@localhost'
        end

    end

    describe :get_from_name do

        it 'finds the first from name' do
            mail = get_fixture_mail('raw_emails/1.email')
            get_from_name(mail).should == 'FOI Person'
        end

    end

    describe :get_all_addresses do

        it 'returns all addresses present in an email' do
            mail = get_fixture_mail('raw_emails/1.email')
            mail.cc = 'bob@example.com'
            mail['envelope-to'] = 'bob@example.net'
            expected = %w(bob@localhost bob@example.com bob@example.net)
            get_all_addresses(mail).should == expected
        end

    end

    describe :empty_return_path? do

        it 'is false if the return path is nil' do
            mail = Mail.new
            empty_return_path?(mail).should be_false
        end

        it 'is false if the return path has some data' do
            mail = Mail.new
            mail['return-path'] = 'xyz'
            empty_return_path?(mail).should be_false
        end

        it 'is true if the return path is blank' do
            mail = Mail.new
            mail['return-path'] = ''
            empty_return_path?(mail).should be_true
        end

    end

    describe :get_auto_submitted do

        it 'returns the auto-submitted attribute' do
            mail = Mail.new
            mail['auto-submitted'] = 'xyz'
            get_auto_submitted(mail).should == 'xyz'
        end

        it 'returns nil if there is no auto-submitted attribute' do
            mail = Mail.new
            get_auto_submitted(mail).should be_nil
        end

    end

    describe :expand_and_normalize_parts do

        context 'when given a multipart message' do

            it 'should return a Mail::PartsList' do
                mail = get_fixture_mail('incoming-request-oft-attachments.email')
                expand_and_normalize_parts(mail, mail).class.should == Mail::PartsList
            end

        end

    end

    describe :address_from_name_and_email do

        it 'returns an address string' do
            expected = 'Test User <test@example.com>'
            address_from_name_and_email('Test User', 'test@example.com').should == expected
        end

        it 'does not change the name passed to it' do
            original = "brønn"
            name = original.dup
            address_from_name_and_email(name, 'test@example.com')
            name.should == original
        end

    end


end
