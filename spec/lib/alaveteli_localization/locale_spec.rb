# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliLocalization::Locale do
  include AlaveteliLocalization::SpecHelpers

  describe '.parse' do
    subject { described_class.parse(identifier) }

    context 'with a simple identifier' do
      let(:identifier) { 'en' }
      it { is_expected.to eq(described_class.new('en')) }
    end

    context 'with a three-character identifier' do
      let(:identifier) { 'ckb' }
      it { is_expected.to eq(described_class.new('ckb')) }
    end

    context 'with a hyphenated identifier' do
      let(:identifier) { 'en-GB' }
      it { is_expected.to eq(hyphenated_locale('en-GB')) }
    end

    context 'with an underscorred identifier' do
      let(:identifier) { 'en_GB' }
      it { is_expected.to eq(underscorred_locale('en_GB')) }
    end

    context 'with an underscorred identifier with a numeric region' do
      let(:identifier) { 'es_419' }
      it { is_expected.to eq(underscorred_locale('es_419')) }
    end

    context 'with an already parsed identifier' do
      let(:identifier) { described_class.parse('en_GB') }
      it { is_expected.to equal(identifier) }
    end

    context 'with an invalid identifier' do
      let(:identifier) { 'foobarbaz' }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'invalid identifier')
      end
    end
  end

  describe '#language' do
    subject { described_class.new('en').language }
    it { is_expected.to eq('en') }
  end

  describe '#region' do
    subject { described_class.new('en').region }
    it { is_expected.to be_nil }
  end

  describe '#canonicalize' do
    subject { described_class.new('en').canonicalize }
    it { is_expected.to eq(subject) }
  end

  describe '#hyphenate' do
    subject { described_class.new('en').hyphenate }
    it { is_expected.to eq(subject) }
  end

  describe '#self_and_parents' do
    subject { described_class.new('en').self_and_parents }
    it { is_expected.to eq(%w[en]) }
  end

  describe '#i18n_fallbacks' do
    context 'without a default_locale' do
      subject { described_class.new('en').i18n_fallbacks }
      it { is_expected.to eq(%i[en]) }
    end

    context 'with a default_locale' do
      subject { described_class.new('en').i18n_fallbacks('fr') }
      it { is_expected.to eq(%i[en fr]) }
    end

    context 'with the default locale given to default_locale' do
      subject { described_class.new('en').i18n_fallbacks('en') }
      it { is_expected.to eq(%i[en]) }
    end

    context 'with a hyphenated default_locale' do
      subject { described_class.new('en').i18n_fallbacks('fr-BE') }
      it { is_expected.to eq(%i[en fr-BE fr_BE fr]) }
    end

    context 'with an underscorred default_locale' do
      subject { described_class.new('en').i18n_fallbacks('fr_BE') }
      it { is_expected.to eq(%i[en fr_BE fr-BE fr]) }
    end
  end

  describe '#to_s' do
    subject { described_class.new('en').to_s }
    it { is_expected.to eq('en') }
  end

  describe '#to_sym' do
    subject { described_class.new('en').to_sym }
    it { is_expected.to eq(:en) }
  end

  describe '#<=>' do
    subject { described_class.new('en') <=> other }

    context 'equal' do
      let(:other) { described_class.new('en') }
      it { is_expected.to eq(0) }
    end

    context 'greater than' do
      let(:other) { described_class.new('ar') }
      it { is_expected.to eq(1) }
    end

    context 'less than' do
      let(:other) { described_class.new('vi') }
      it { is_expected.to eq(-1) }
    end
  end
end
