require 'spec_helper'

RSpec.describe Admin::CitationsHelper do
  include Admin::CitationsHelper

  describe '#citation_icon' do
    subject { citation_icon(citation) }

    context 'with a news story' do
      let(:citation) { FactoryBot.build(:citation, type: 'news_story') }
      it { is_expected.to include('🗞️') }
      it { is_expected.to include('citation-icon--news_story') }
    end

    context 'with an academic paper' do
      let(:citation) { FactoryBot.build(:citation, type: 'academic_paper') }
      it { is_expected.to include('🎓') }
      it { is_expected.to include('citation-icon--academic_paper') }
    end

    context 'with a generic link' do
      let(:citation) { FactoryBot.build(:citation, type: 'other') }
      it { is_expected.to include('🌐') }
      it { is_expected.to include('citation-icon--other') }
    end
  end
end
