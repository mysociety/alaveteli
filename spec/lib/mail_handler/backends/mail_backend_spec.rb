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

    subject { mail_from_raw_email(raw_email) }

    context 'when passed a binary string' do
      # Read fixture file using 'rb' mode so we end up with a ASCII-8BIT string
      let(:raw_email) { load_file_fixture('raw_emails/1.email', 'rb') }

      it 'does not raise error' do
        expect { subject }.to_not raise_error
      end

      it 'returns a new mail instance of the email' do
        is_expected.to eq Mail.read_from_string(raw_email)
      end
    end

    context 'when passed an UTF-8 string' do
      let(:raw_email) do
        # Read fixture file using 'r' mode so we end up with a UTF-8 string
        load_file_fixture('iso8859_1_with_extended_character_set.email', 'r')
      end

      it 'does not raise error' do
        expect { subject }.to_not raise_error
      end

      it 'returns a new mail with binary body' do
        expect(subject.body.to_s).to eq(
          "Information Governance\xA0Unit".force_encoding(Encoding::BINARY)
        )
      end
    end

    context 'when passed a mail' do
      let(:raw_email) do
        Mail.new(
          load_file_fixture('incoming-request-attach-attachments.email')
        ).body
      end

      it 'does not raise error' do
        expect { subject }.to_not raise_error
      end

      it 'returns a new mail instance of the email' do
        is_expected.to eq Mail.read_from_string(raw_email)
      end
    end

    it 'correctly parses mails with unix line endings' do
      filename = 'incoming-pdf-attachment-unix-line-endings.eml'
      file = Rails.root.join('spec/fixtures/files', filename)

      expected = ["text/plain; charset=utf-8; format=flowed",
                  "application/pdf; name=\"20200819 - Aerial Images.pdf\""]

      parts =
        MailHandler.mail_from_raw_email(File.open(file, 'rb') { |f| f.read }).
        parts.
        map { |part| part.content_type.to_s }.to_a

      expect(parts).to eq(expected)
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

  describe :get_subject do

    it 'returns nil for a nil subject' do
      mail = Mail.new
      expect(get_subject(mail)).to be nil
    end

    it 'returns valid UTF-8 for a non UTF-8 subject' do
      mail = Mail.new
      allow(mail).to receive(:subject).and_return("FOI ACT \x96 REQUEST")
      expect(get_subject(mail).force_encoding('UTF-8').valid_encoding?)
        .to be true
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

  describe '.get_all_addresses' do
    let(:valid_only) do
      mail = Mail.new(<<-EOF.strip_heredoc)
      From: "FOI Person" <foiperson@localhost>
      To: "Bob Smith" <bob@localhost>
      Cc: bob@example.com
      Envelope-To: bob@example.net
      Date: Tue, 13 Nov 2007 11:39:55 +0000
      Bcc:
      Subject: Test
      Reply-To:

      Test
      EOF
    end

    let(:with_invalid) do
      mail = Mail.new(<<-EOF.strip_heredoc)
      From: "FOI Person" <foiperson@localhost>
      To: <Bob Smith <bob@localhost>
      Cc: bob@example.com>
      Envelope-To: bob@example.net
      Date: Tue, 13 Nov 2007 11:39:55 +0000
      Bcc:
      Subject: Test
      Reply-To:

      Test
      EOF
    end

    context 'include_invalid: false' do
      subject { MailHandler.get_all_addresses(mail) }

      context 'with a mail with only valid addresses' do
        let(:mail) { valid_only }

        it do
          is_expected.to eq(%w(bob@localhost bob@example.com bob@example.net))
        end
      end

      context 'with an email with invalid addresses' do
        let(:mail) { with_invalid }
        it { is_expected.to eq(%w(bob@example.net)) }
      end
    end

    context 'include_invalid: true' do
      subject { MailHandler.get_all_addresses(mail, include_invalid: true) }

      context 'with a mail with only valid addresses' do
        let(:mail) { valid_only }

        it do
          is_expected.to eq(%w(bob@localhost bob@example.com bob@example.net))
        end
      end

      context 'with an email with invalid addresses' do
        let(:mail) { with_invalid }

        it do
          expected = ['<Bob Smith <bob@localhost>',
                      'bob@example.com>',
                      'bob@example.net']
          is_expected.to eq(expected)
        end
      end
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

  describe '#decode_attached_part' do
    it 'does not error if mapi cannot parse a part' do
      allow(Mapi::Msg).to receive(:open).and_raise(Encoding::CompatibilityError)
      mail = get_fixture_mail('incoming-request-oft-attachments.email')
      expect { decode_attached_part(mail.parts.last, mail) }.not_to raise_error
    end
  end
end
