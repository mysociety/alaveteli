require 'spec_helper'

RSpec.describe Legislation::ReferenceCollection do
  let(:foia) { Legislation.default }

  let(:legislation_collection) do
    Legislation::ReferenceCollection.new(legislation: foia)
  end

  describe '.match' do
    subject(:matches) { legislation_collection.match(input) }

    context 'basic matches' do
      let(:input) do <<~EOI end
        Section 1
        Section 2.1
        Section 3(1)
        Section 4 (1)
      EOI

      it { is_expected.to all(be_a(Legislation::Reference)) }

      it 'returns correct refs' do
        expect(matches.map(&:to_s)).to match_array(
          ['Section 1', 'Section 2(1)', 'Section 3(1)', 'Section 4(1)']
        )
      end
    end

    context 'chained matches' do
      let(:input) do <<~EOI end
        Section 1 or 11
        Section 2.1 or 12.1
        Section 3(1) or 13(1)
        Section 4 (1) or 14 (1)
        Section 5.1.a&b or 15.1.a&b
        Section 6(1)(a)&(b) or 16(1)(a)&(b)
      EOI

      it { is_expected.to all(be_a(Legislation::Reference)) }

      it 'returns correct refs' do
        expect(matches.map(&:to_s)).to match_array(
          ['Section 1', 'Section 11',
           'Section 2(1)', 'Section 12(1)',
           'Section 3(1)', 'Section 13(1)',
           'Section 4(1)', 'Section 14(1)',
           'Section 5(1)(a)', 'Section 5(1)(b)',
           'Section 15(1)(a)', 'Section 15(1)(b)',
           'Section 6(1)(a)', 'Section 6(1)(b)',
           'Section 16(1)(a)', 'Section 16(1)(b)']
        )
      end
    end

    context 'abbreviated' do
      let(:input) do <<~EOI end
        S. 1(1)
        S.2(1)
      EOI

      it { is_expected.to all(be_a(Legislation::Reference)) }

      it 'returns correct refs' do
        expect(matches.map(&:to_s)).to match_array(
          ['Section 1(1)', 'Section 2(1)']
        )
      end
    end

    context 'other types of legislation' do
      let(:input) do <<~EOI end
        Article 1
        art. 2(1)
        Regulation 3
        reg. 4(1)
      EOI

      it { is_expected.to all(be_a(Legislation::Reference)) }

      it 'returns correct refs' do
        expect(matches.map(&:to_s)).to match_array(
          ['Article 1', 'Article 2(1)',
           'Regulation 3', 'Regulation 4(1)']
        )
      end
    end

    context 'invalid types of legislation' do
      let(:input) do <<~EOI end
        Invalid 1
        inv. 2
      EOI

      it { is_expected.to be_empty }
    end

    context 'paragraphs elements' do
      let(:input) do <<~EOI end
        S.1.1.a
        S.2(1)(b)&(c)
      EOI

      it { is_expected.to all(be_a(Legislation::Reference)) }

      it 'returns correct refs' do
        expect(matches.map(&:to_s)).to match_array(
          ['Section 1(1)(a)', 'Section 2(1)(b)', 'Section 2(1)(c)']
        )
      end
    end

    context 'subparagraphs elements' do
      let(:input) do <<~EOI end
        S.1.1.a.i
        S.2(1)(b)(i)&(ii)
      EOI

      it { is_expected.to all(be_a(Legislation::Reference)) }

      it 'returns correct refs' do
        expect(matches.map(&:to_s)).to match_array(
          ['Section 1(1)(a)(i)', 'Section 2(1)(b)(i)', 'Section 2(1)(b)(ii)']
        )
      end
    end
  end
end
