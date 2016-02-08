# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OutgoingMessage::Template::BatchRequest do

  describe '.placeholder_salutation' do

    it 'returns the placeholder salutation' do
      expect(described_class.placeholder_salutation).
        to eq('Dear [Authority name],')
    end

  end

  describe '#body' do

    it 'returns the expected template text' do
      expected = "Dear [Authority name],\n\n\n\nYours faithfully,\n\n"
      expect(subject.body).to eq(expected)
    end

    it 'allows a custom message letter' do
      opts = { :letter => 'A custom letter' }
      expected = "Dear [Authority name],\n\nA custom letter\n\n\n\nYours faithfully,\n\n"
      expect(subject.body(opts)).to eq(expected)
    end

  end

  describe '#salutation' do

    it 'returns the salutation' do
      expect(subject.salutation).to eq('Dear [Authority name],')
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
      expect(subject.signoff).to eq('Yours faithfully,')
    end

  end

end
