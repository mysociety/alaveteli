require 'spec_helper'

RSpec.describe CensorRule::DiacriticExpander do
  describe '.character_map' do
    subject { described_class.character_map }

    after do
      described_class.character_map = described_class::DEFAULT_CHARACTER_MAP
    end

    context 'with the default map' do
      it { is_expected.to eq(described_class::DEFAULT_CHARACTER_MAP) }
    end

    context 'with a custom map' do
      let(:custom_map) do
        { 'x' => '[xxyz]', 'X' => '[XXYZ]' }
      end

      before { described_class.character_map = custom_map }

      it { is_expected.to eq(custom_map) }
    end
  end

  describe '#expand' do
    context 'with default case-sensitive mode' do
      subject(:expander) { described_class.new }

      it 'expands lowercase characters with diacritics to character classes' do
        expect(expander.expand('a')).to eq('[aàáâãäåā]')
      end

      it 'expands uppercase characters with diacritics to character classes' do
        expect(expander.expand('A')).to eq('[AÀÁÂÃÄÅĀ]')
      end

      it 'preserves characters without diacritic variants' do
        expect(expander.expand('b')).to eq('b')
      end

      it 'ignores non-mapped characters' do
        expect(expander.expand('123')).to eq('123')
        expect(expander.expand('!@*')).to eq('!@*')
      end

      it 'handles multi-character strings' do
        expect(expander.expand('café')).to eq('[cçćč][aàáâãäåā]f[eèéêëēě]')
      end

      it 'handles mixed mapped and non-mapped characters' do
        expect(expander.expand('a1b2c')).to eq('[aàáâãäåā]1b2[cçćč]')
      end

      it 'handles diacritic characters themselves' do
        expect(expander.expand('á')).to eq('[aàáâãäåā]')
        expect(expander.expand('Á')).to eq('[AÀÁÂÃÄÅĀ]')
      end

      it 'handles multi-character diacritics' do
        expect(expander.expand('œ')).to eq('(œ|oe)')
        expect(expander.expand('Œ')).to eq('(Œ|OE)')
      end

      it 'handles strings with spaces and punctuation' do
        expected =
          '[cçćč][aàáâãäåā]f[eèéêëēě] ' \
          '[aàáâãäåā][uùúûüūů] ' \
          '[lłĺļľ][aàáâãäåā][iìíîïī]t'

        expect(expander.expand('café au lait')).to eq(expected)
      end

      it 'handles empty strings' do
        expect(expander.expand('')).to eq('')
      end
    end

    context 'with case-insensitive mode' do
      subject(:expander) { described_class.new(case_sensitive: false) }

      it 'merges character classes for both cases' do
        expect(expander.expand('a')).to eq('[aàáâãäåāAÀÁÂÃÄÅĀ]')
        expect(expander.expand('A')).to eq('[aàáâãäåāAÀÁÂÃÄÅĀ]')
      end

      it 'handles mixed case strings' do
        expect(expander.expand('Café')).
          to eq('[cçćčCÇĆČ][aàáâãäåāAÀÁÂÃÄÅĀ]f[eèéêëēěEÈÉÊËĒĚ]')
      end

      it 'handles strings with only uppercase' do
        expect(expander.expand('CAFÉ')).
          to eq('[cçćčCÇĆČ][aàáâãäåāAÀÁÂÃÄÅĀ]F[eèéêëēěEÈÉÊËĒĚ]')
      end

      it 'ignores non-mapped characters the same as case-sensitive' do
        expect(expander.expand('123')).to eq('123')
        expect(expander.expand('!@*')).to eq('!@*')
      end

      it 'handles diacritic characters in case-insensitive mode' do
        expect(expander.expand('á')).to eq('[aàáâãäåāAÀÁÂÃÄÅĀ]')
        expect(expander.expand('Á')).to eq('[aàáâãäåāAÀÁÂÃÄÅĀ]')
      end
    end
  end

  describe '#case_sensitive?' do
    it 'returns true by default' do
      expander = described_class.new
      expect(expander.case_sensitive?).to eq(true)
    end

    it 'returns false when case_sensitive is set to false' do
      expander = described_class.new(case_sensitive: false)
      expect(expander.case_sensitive?).to eq(false)
    end
  end
end
