# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '../../../../spec_helper')

describe MailHandler::Backends::MailBackend do
  include MailHandler
  include MailHandler::Backends::MailBackend

  describe :backend do

    it 'should return the name of the backend' do
      expect(backend).to eq('Mail')
    end

  end

  describe :mail_from_raw_email do

    it 'returns a new mail instance of the email' do
      raw_mail = load_file_fixture('raw_emails/1.email')
      expected = Mail.read_from_string(raw_mail)
      expect(mail_from_raw_email(raw_mail)).to eq(expected)
    end

  end

  describe :get_part_file_name do

    it 'returns the part file name' do
      mail = get_fixture_mail('document-pdf.email')
      part = mail.attachments.first
      expect(get_part_file_name(part)).to eq('tiny-example.pdf')
    end

    it 'returns nil if there is no file name' do
      mail = get_fixture_mail('document-pdf.email')
      part = mail.parts.first
      expect(get_part_file_name(part)).to be_nil
    end

    it 'turns an invalid UTF-8 name into a valid one' do
      mail = get_fixture_mail('non-utf8-filename.email')
      part = mail.attachments.first
      filename = get_part_file_name(part)
      if filename.respond_to?(:valid_encoding)
        expect(filename.valid_encoding?).to eq(true)
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
      expect(get_part_body(part)).to eq(expected)
    end

  end

  describe :first_from do

    it 'finds the first from field' do
      mail = get_fixture_mail('raw_emails/1.email')
      expected = Mail::Address.new('FOI Person <foiperson@localhost>').to_s
      expect(first_from(mail).to_s).to eq(expected)
    end

  end

  describe :get_from_address do

    it 'finds the first address' do
      mail = get_fixture_mail('raw_emails/1.email')
      expect(get_from_address(mail)).to eq('foiperson@localhost')
    end

  end

  describe :get_from_name do

    it 'finds the first from name' do
      mail = get_fixture_mail('raw_emails/1.email')
      expect(get_from_name(mail)).to eq('FOI Person')
    end

  end

  describe :get_all_addresses do

    it 'returns all addresses present in an email' do
      mail = get_fixture_mail('raw_emails/1.email')
      mail.cc = 'bob@example.com'
      mail['envelope-to'] = 'bob@example.net'
      expected = %w(bob@localhost bob@example.com bob@example.net)
      expect(get_all_addresses(mail)).to eq(expected)
    end

  end

  describe :empty_return_path? do

    it 'is false if the return path is nil' do
      mail = Mail.new
      expect(empty_return_path?(mail)).to be false
    end

    it 'is false if the return path has some data' do
      mail = Mail.new
      mail['return-path'] = 'xyz'
      expect(empty_return_path?(mail)).to be false
    end

    it 'is true if the return path is blank' do
      mail = Mail.new
      mail['return-path'] = ''
      expect(empty_return_path?(mail)).to be true
    end

  end

  describe :get_auto_submitted do

    it 'returns the auto-submitted attribute' do
      mail = Mail.new
      mail['auto-submitted'] = 'xyz'
      expect(get_auto_submitted(mail)).to eq('xyz')
    end

    it 'returns nil if there is no auto-submitted attribute' do
      mail = Mail.new
      expect(get_auto_submitted(mail)).to be_nil
    end

  end

  describe :expand_and_normalize_parts do

    context 'when given a multipart message' do

      it 'should return a Mail::PartsList' do
        mail = get_fixture_mail('incoming-request-oft-attachments.email')
        expect(expand_and_normalize_parts(mail, mail).class).to eq(Mail::PartsList)
      end

    end

  end

  describe :address_from_name_and_email do

    it 'returns an address string' do
      expected = 'Test User <test@example.com>'
      expect(address_from_name_and_email('Test User', 'test@example.com')).to eq(expected)
    end

    it 'does not change the name passed to it' do
      original = "brønn"
      name = original.dup
      address_from_name_and_email(name, 'test@example.com')
      expect(name).to eq(original)
    end

  end


end
