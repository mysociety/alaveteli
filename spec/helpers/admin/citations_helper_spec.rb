require 'spec_helper'

RSpec.describe Admin::CitationsHelper do
  include Admin::CitationsHelper

  describe '#citation_title' do
    subject { citation_title(citation) }

    context 'with a citation that has a title' do
      let(:citation) { FactoryBot.build(:citation, title: 'Example Title') }
      it { is_expected.to eq('Example Title') }
    end

    context 'with a citation that has a blank title' do
      let(:citation) do
        FactoryBot.build(:citation, title: '', source_url: 'http://example.com')
      end

      it { is_expected.to eq('http://example.com') }
    end
  end

  describe '#citation_icon' do
    subject { citation_icon(citation) }

    context 'with a journalism link' do
      let(:citation) { FactoryBot.build(:citation, type: 'journalism') }
      it { is_expected.to include('🗞️') }
      it { is_expected.to include('citation-icon--journalism') }
    end

    context 'with an research link' do
      let(:citation) { FactoryBot.build(:citation, type: 'research') }
      it { is_expected.to include('📚') }
      it { is_expected.to include('citation-icon--research') }
    end

    context 'with a generic link' do
      let(:citation) { FactoryBot.build(:citation, type: 'other') }
      it { is_expected.to include('🌐') }
      it { is_expected.to include('citation-icon--other') }
    end
  end
end
