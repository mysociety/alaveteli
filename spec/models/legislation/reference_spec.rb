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

      it 'returns reference type and parent element' do
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

  describe '#cover?' do
    let(:parent) do
      Legislation::Reference.new(legislation: foi, reference: 's 1')
    end

    let(:child) do
      Legislation::Reference.new(legislation: foi, reference: 's 1(a)')
    end

    it 'returns true if other reference is a subreference' do
      expect(parent.cover?(child)).to eq true
    end

    it 'returns false if other reference is not a subreference' do
      expect(child.cover?(parent)).to eq false
    end

    it 'returns false if other reference belongs to a different legislation' do
      eir = Legislation::Reference.new(legislation: eir, reference: 's 1(a)')
      expect(parent.cover?(eir)).to eq false
    end

    it 'returns false if other reference is a different type' do
      art = Legislation::Reference.new(legislation: foi, reference: 'art 1(a)')
      expect(parent.cover?(art)).to eq false
    end
  end

  describe '#refusal?' do
    let(:reference) do
      Legislation::Reference.new(legislation: foi, reference: 'Section 12(1)')
    end

    subject { reference.refusal? }

    context 'legislation has refusal covering reference' do
      before { allow(foi).to receive(:refusals).and_return([reference]) }
      it { is_expected.to eq true }
    end

    context 'legislation does not have refusal covering reference' do
      before { allow(foi).to receive(:refusals).and_return([]) }
      it { is_expected.to eq false }
    end
  end
end
