# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OutgoingMessage::Template::InternalReview do

  describe '.details_placeholder' do

    it 'returns the internal review placeholder text' do
      expect(described_class.details_placeholder).
        to eq('GIVE DETAILS ABOUT YOUR COMPLAINT HERE')
    end

  end

  describe '#body' do

    it 'requires a :public_body_name key' do
      attrs = { :info_request_title => 'a', :url => 'b' }
      msg = 'Missing required key: public_body_name'
      expect { subject.body(attrs) }.to raise_error(ArgumentError, msg)
    end

    it 'requires an :info_request_title key' do
      attrs = { :public_body_name => 'a', :url => 'b' }
      msg = 'Missing required key: info_request_title'
      expect { subject.body(attrs) }.to raise_error(ArgumentError, msg)
    end

    it 'requires a :url key' do
      attrs = { :public_body_name => 'a', :info_request_title => 'b' }
      msg = 'Missing required key: url'
      expect { subject.body(attrs) }.to raise_error(ArgumentError, msg)
    end

    it 'returns the expected template text' do
      attrs = { :public_body_name => 'A body',
                :info_request_title => 'a test title',
                :url => 'http://test.host/request/a_test_title' }

      expected = <<-EOF.strip_heredoc
      Dear A body,

      Please pass this on to the person who conducts Freedom of Information reviews.

      I am writing to request an internal review of A body's handling of my FOI request 'a test title'.



       [ GIVE DETAILS ABOUT YOUR COMPLAINT HERE ] 



      A full history of my FOI request and all correspondence is available on the Internet at this address: http://test.host/request/a_test_title


      Yours faithfully,

      EOF

      expect(subject.body(attrs)).to eq(expected)
    end

    it 'allows a custom message letter' do
      attrs = { :public_body_name => 'A body',
                :info_request_title => 'a test title',
                :url => 'http://test.host/request/a_test_title',
                :letter => 'A custom letter' }
      expected = "Dear A body,\n\nA custom letter\n\n\nYours faithfully,\n\n"
      expect(subject.body(attrs)).to eq(expected)
    end

  end

  describe '#salutation' do

    it 'returns the salutation' do
      expect(subject.salutation(:public_body_name => 'A body')).
        to eq('Dear A body,')
    end

  end

  describe '#letter' do

    it 'returns the letter' do
      attrs = { :public_body_name => 'A body',
                :info_request_title => 'a test title',
                :url => 'http://test.host/request/a_test_title' }

      expected = <<-EOF.strip_heredoc


      Please pass this on to the person who conducts Freedom of Information reviews.

      I am writing to request an internal review of A body's handling of my FOI request 'a test title'.



       [ GIVE DETAILS ABOUT YOUR COMPLAINT HERE ] 



      A full history of my FOI request and all correspondence is available on the Internet at this address: http://test.host/request/a_test_title
      EOF
      expected.chomp!

      expect(subject.letter(attrs)).to eq(expected)
    end

    it 'returns a custom letter' do
      expect(subject.letter(:letter => 'custom')).to eq("\n\ncustom")
    end

  end

  describe '#signoff' do

    it 'returns the signoff' do
      expect(subject.signoff).to eq('Yours faithfully,')
    end

  end

end
