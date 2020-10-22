require 'spec_helper'

RSpec.describe Legislation::Reference do
  let(:foi) { Legislation.find!('foi') }
  let(:eir) { Legislation.find!('eir') }

  def reference_with_type(type)
    Legislation::Reference.new(legislation: foi, reference: "#{type} 1")
  end

  describe 'initialiation' do
    it 'accepts legislation, type and reference attributes' do
      ref = Legislation::Reference.new(
        legislation: foi, reference: 'Section 12(1)'
      )
      expect(ref.legislation).to eq foi
      expect(ref.type).to eq 'Section'
      expect(ref.elements).to match_array(%w(12 1))
    end

    it 'maps known reference types' do
      expect(reference_with_type('s').type).to eq 'Section'
      expect(reference_with_type('section').type).to eq 'Section'
      expect(reference_with_type('art').type).to eq 'Article'
      expect(reference_with_type('article').type).to eq 'Article'
      expect(reference_with_type('reg').type).to eq 'Regulation'
      expect(reference_with_type('regulation').type).to eq 'Regulation'
    end

    it 'raises error for invalid reference type' do
      expect { reference_with_type('invalid') }.to raise_error(
        Legislation::InvalidReferenceType,
        'Unknown legislation reference type invalid.'
      )
    end
  end

  describe '#to_s' do
    subject { legislation.to_s }

    context 'without sub elements' do
      let(:legislation) do
        Legislation::Reference.new(legislation: foi, reference: 's 1')
      end

      it 'returns reference type and main element' do
        is_expected.to eq 'Section 1'
      end
    end

    context 'with sub elements' do
      let(:legislation) do
        Legislation::Reference.new(legislation: foi, reference: 's 1(a)')
      end

      it 'returns reference with bracketed sub elements' do
        is_expected.to eq 'Section 1(a)'
      end
    end
  end
end
