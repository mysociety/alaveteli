# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AlaveteliSpamTermChecker do

  after(:each) do
    described_class.default_spam_terms = described_class::DEFAULT_SPAM_TERMS
  end

  describe '.default_spam_terms' do

    it 'returns the DEFAULT_SPAM_TERMS if no custom terms have been set' do
      expect(described_class.default_spam_terms).
        to eq(described_class::DEFAULT_SPAM_TERMS)
    end

  end

  describe '.default_spam_terms=' do

    it 'sets custom terms' do
      described_class.default_spam_terms = [/a/, /b/, /c/]
      expect(described_class.default_spam_terms).to eq([/a/, /b/, /c/])
    end

    it 'converts a single term to an array' do
      described_class.default_spam_terms = /a/
      expect(described_class.default_spam_terms).to eq([/a/])
    end

    it 'converts a String term to a Regexp' do
      described_class.default_spam_terms = 'a'
      expect(described_class.default_spam_terms).to eq([/a/])
    end

    it 'handles mixed String and Regexp terms' do
      described_class.default_spam_terms = [/a/, 'b', /c/]
      expect(described_class.default_spam_terms).to eq([/a/, /b/, /c/])
    end

    it 'allows an empty set of terms' do
      described_class.default_spam_terms = []
      expect(described_class.default_spam_terms).to eq([])
    end

    it 'allows an empty set of terms when given nil' do
      described_class.default_spam_terms = nil
      expect(described_class.default_spam_terms).to eq([])
    end

    it 'does not allow an invalid term' do
      expect { described_class.default_spam_terms = Object.new }.
        to raise_error(TypeError)
    end

  end

  describe '.new' do

    it 'sets the default terms if none are given' do
      expect(subject.spam_terms).to eq(described_class.default_spam_terms)
    end

    it 'sets the custom default spam terms if none are given' do
      described_class.default_spam_terms = [/a/, 'b', /c/]
      expect(subject.spam_terms).to eq([/a/, /b/, /c/])
    end

    it 'sets custom terms' do
      subject = described_class.new([/a/, /b/, /c/])
      expect(subject.spam_terms).to eq([/a/, /b/, /c/])
    end

    it 'converts a single term to an array' do
      subject = described_class.new(/a/)
      expect(subject.spam_terms).to eq([/a/])
    end

    it 'converts a String term to a Regexp' do
      subject = described_class.new('a')
      expect(subject.spam_terms).to eq([/a/])
    end

    it 'handles mixed String and Regexp terms' do
      subject = described_class.new([/a/, 'b', /c/])
      expect(subject.spam_terms).to eq([/a/, /b/, /c/])
    end

    it 'allows an empty set of terms' do
      subject = described_class.new([])
      expect(subject.spam_terms).to eq([])
    end

    it 'does not allow an invalid term' do
      expect { described_class.new(Object.new) }.
        to raise_error(TypeError)
    end

  end

  describe '#spam?' do

    it 'returns true if the term matches a spam term' do
      subject = described_class.new([/hello/, 'world'])
      expect(subject.spam?('hi world')).to eq(true)
    end

    it 'returns false if the term does not match any spam terms' do
      subject = described_class.new([/hello/, 'world'])
      expect(subject.spam?('hey globe')).to eq(false)
    end

  end

end
