# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliLocalization::HyphenatedLocale do
  include AlaveteliLocalization::SpecHelpers

  let(:identifier) { 'en-GB' }

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
    it { is_expected.to eq(underscorred_locale('en_GB')) }
  end

  describe '#hyphenate' do
    subject { described_class.new(identifier).hyphenate }
    it { is_expected.to eq(subject) }
  end

  describe '#self_and_parents' do
    subject { described_class.new(identifier).self_and_parents }
    it { is_expected.to eq(%w[en-GB en_GB en]) }
  end

  describe '#i18n_fallbacks' do
    context 'without a default_locale' do
      subject { described_class.new(identifier).i18n_fallbacks }
      it { is_expected.to eq(%i[en-GB en_GB en]) }
    end

    context 'with a default_locale' do
      subject { described_class.new(identifier).i18n_fallbacks('fr') }
      it { is_expected.to eq(%i[en-GB en_GB en fr]) }
    end

    context 'with the default locale given to default_locale' do
      subject { described_class.new(identifier).i18n_fallbacks(identifier) }
      it { is_expected.to eq(%i[en-GB en_GB en]) }
    end

    context 'with a hyphenated default_locale' do
      subject { described_class.new(identifier).i18n_fallbacks('fr-BE') }
      it { is_expected.to eq(%i[en-GB en_GB en fr-BE fr_BE fr]) }
    end

    context 'with an underscorred default_locale' do
      subject { described_class.new(identifier).i18n_fallbacks('fr_BE') }
      it { is_expected.to eq(%i[en-GB en_GB en fr_BE fr-BE fr]) }
    end
  end

  describe '#to_s' do
    subject { described_class.new(identifier).to_s }
    it { is_expected.to eq('en-GB') }
  end

  describe '#to_sym' do
    subject { described_class.new(identifier).to_sym }
    it { is_expected.to eq(:'en-GB') }
  end
end
