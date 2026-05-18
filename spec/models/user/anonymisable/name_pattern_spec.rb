require 'spec_helper'

RSpec.describe User::Anonymisable::NamePattern do
  describe '.honorifics' do
    subject { described_class.honorifics }
    it { is_expected.to eq('Mr|Mrs|Miss|Ms|Mx') }
  end

  describe '.honorifics=' do
    before { described_class.honorifics = 'Dr' }
    after { described_class.honorifics = described_class::DEFAULT_HONORIFICS }

    subject { described_class.honorifics }

    it { is_expected.to eq('Dr') }
  end

  describe '.pattern' do
    subject { described_class.pattern }

    it { is_expected.to eq(described_class::DEFAULT_PATTERN) }

    describe 'default matches common name variants' do
      common_name_variants = [
        'Bob Smith',
        'Bob',
        'B Smith',
        'B. Smith',
        'Bob S',
        'Smith, Bob',
        'Smith, B',
        'Mr Smith',
        'Mr. Smith',
        'Mr B Smith',
        'Mr B. Smith',
        'Mr. B Smith',
        'Mr Bob Smith',
        'Mr. Bob Smith',
        'Mrs Smith',
        'Mrs. Smith',
        'Mrs B Smith',
        'Mrs B. Smith',
        'Mrs. B Smith',
        'Mrs Bob Smith',
        'Mrs. Bob Smith',
        'Miss Smith',
        'Miss. Smith',
        'Miss B Smith',
        'Miss B. Smith',
        'Miss. B Smith',
        'Miss Bob Smith',
        'Miss. Bob Smith',
        'Ms Smith',
        'Ms. Smith',
        'Ms B Smith',
        'Ms B. Smith',
        'Ms. B Smith',
        'Ms Bob Smith',
        'Ms. Bob Smith',
        'Mx Smith',
        'Mx. Smith',
        'Mx B Smith',
        'Mx B. Smith',
        'Mx. B Smith',
        'Mx Bob Smith',
        'Mx. Bob Smith'
      ]

      common_name_variants.each do |variant|
        context "with name '#{variant}'" do
          subject { variant }

          let(:regexp) do
            Regexp.new(described_class.new('Bob Smith').to_censor_rule_text)
          end

          it { is_expected.to match(regexp) }
        end
      end
    end
  end

  describe '.pattern=' do
    before { described_class.pattern = 'x' }
    after { described_class.pattern = described_class::DEFAULT_PATTERN }

    subject { described_class.pattern }

    it { is_expected.to eq('x') }
  end

  describe '#firstname' do
    subject { described_class.new(name).firstname }

    context 'with a simple name' do
      let(:name) { 'John Smith' }
      it { is_expected.to eq('John') }
    end
  end

  describe '#first_initial' do
    subject { described_class.new(name).first_initial }

    context 'with a simple name' do
      let(:name) { 'John Smith' }
      it { is_expected.to eq('J') }
    end

    context 'with a multibyte first character' do
      let(:name) { 'Ångström Svensson' }
      it { is_expected.to eq('Å') }
    end
  end

  describe '#surname' do
    subject { described_class.new(name).surname }

    context 'with a two-part name' do
      let(:name) { 'John Smith' }
      it { is_expected.to eq('Smith') }
    end

    context 'with more than two parts' do
      let(:name) { 'Mary Jane Watson' }
      it { is_expected.to eq('Watson') }
    end

    context 'with a single word' do
      let(:name) { 'Madonna' }
      it { is_expected.to eq('Madonna') }
    end
  end

  describe '#last_initial' do
    subject { described_class.new(name).last_initial }

    context 'with a simple name' do
      let(:name) { 'John Smith' }
      it { is_expected.to eq('S') }
    end

    context 'with a multibyte first character in the surname' do
      let(:name) { 'John Ångström' }
      it { is_expected.to eq('Å') }
    end

    context 'with a single character surname' do
      let(:name) { 'Cédric O' }
      it { is_expected.to eq('O') }
    end
  end

  describe '#to_h' do
    subject { described_class.new('John S-mith').to_h }

    it do
      is_expected.to eq(
        firstname: 'John',
        surname: 'S-mith',
        first_initial: 'J',
        last_initial: 'S',
        honorifics: 'Mr|Mrs|Miss|Ms|Mx'
      )
    end
  end

  describe '#substitutions' do
    subject { described_class.new('John S-mith').substitutions }

    it do
      is_expected.to eq(
        firstname: 'John',
        surname: 'S\\-mith',
        first_initial: 'J',
        last_initial: 'S',
        honorifics: 'Mr|Mrs|Miss|Ms|Mx'
      )
    end
  end

  describe '#to_censor_rule_text' do
    subject { described_class.new('Bob Smith').to_censor_rule_text }

    it { is_expected.to eq("(?x:\n    \\b\n    (?:\n      (?:Mr|Mrs|Miss|Ms|Mx)\\.? \\s+ (?:Bob\\s+)? Smith\n      |\n      Bob (?: \\s+ Smith | \\s+ S\\.? )?\n      |\n      B\\.? \\s* Smith\n      |\n      Smith ,\\s+ (?: Bob | B\\.? )\n    )\n    (?!\\w)\n  )") }

    context 'with a custom pattern' do
      around do |example|
        described_class.pattern = '%{firstname} %{first_initial} %{last_initial} %{surname}'
        example.run
        described_class.pattern = described_class::DEFAULT_PATTERN
      end

      it { is_expected.to eq('Bob B S Smith') }
    end

    context 'with custom honorifics' do
      around do |example|
        described_class.honorifics = 'Monsieur|M|Madame|Mme'
        example.run
        described_class.honorifics = described_class::DEFAULT_HONORIFICS
      end

      it { is_expected.to include('Monsieur|M|Madame|Mme') }
    end
  end
end
