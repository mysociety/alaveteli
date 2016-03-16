# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OutgoingMessage::Template::IncomingMessageFollowup do

  describe '#body' do

    it 'requires a :public_body_name key' do
      msg = 'Missing required key: public_body_name'
      expect { subject.body }.to raise_error(ArgumentError, msg)
    end

    it 'returns the expected template text' do
      expected = "Dear A body,\n\n\n\nYours sincerely,\n\n"
      expect(subject.body(:public_body_name => 'A body')).to eq(expected)
    end

    it 'allows a custom message letter' do
      opts = { :public_body_name => 'A body',
               :letter => 'A custom letter' }
      expected = "Dear A body,\n\nA custom letter\n\n\n\nYours sincerely,\n\n"
      expect(subject.body(opts)).to eq(expected)
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
      expect(subject.letter).to eq('')
    end

    it 'returns a custom letter' do
      expect(subject.letter(:letter => 'custom')).to eq("\n\ncustom")
    end

  end

  describe '#signoff' do

    it 'returns the signoff' do
      expect(subject.signoff).to eq('Yours sincerely,')
    end

  end

end
