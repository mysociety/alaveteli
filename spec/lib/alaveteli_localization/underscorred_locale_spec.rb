# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliLocalization::UnderscorredLocale do
  include AlaveteliLocalization::SpecHelpers

  let(:identifier) { 'en_GB' }

  describe '#language' do
    subject { described_class.new(identifier).language }
    it { is_expected.to eq('en') }
  end

  describe '#region' do
    subject { described_class.new(identifier).region }
    it { is_expected.to eq('GB') }
  end

  describe '#canonicalize' do
    subject { described_class.new(identifier).canonicalize }
    it { is_expected.to eq(subject) }
  end

  describe '#hyphenate' do
    subject { described_class.new(identifier).hyphenate }
    it { is_expected.to eq(hyphenated_locale('en-GB')) }
  end

  describe '#self_and_parents' do
    subject { described_class.new(identifier).self_and_parents }
    # Note that self_and_parents only uses hyphenated locales
    it { is_expected.to eq(%w[en-GB en]) }
  end

  describe '#to_s' do
    subject { described_class.new(identifier).to_s }
    it { is_expected.to eq('en_GB') }
  end

  describe '#to_sym' do
    subject { described_class.new(identifier).to_sym }
    it { is_expected.to eq(:en_GB) }
  end
end
