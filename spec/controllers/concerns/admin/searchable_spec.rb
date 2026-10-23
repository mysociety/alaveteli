require 'spec_helper'

RSpec.describe Admin::Searchable do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include Admin::Searchable
    end
  end

  let(:controller) { controller_class.new }

  before do
    allow(controller).to receive(:params).and_return(
      ActionController::Parameters.new(search_engine: search_engine)
    )
  end

  describe '#search_engine' do
    subject { controller.search_engine }

    context 'when the legacy engine is requested' do
      let(:search_engine) { 'legacy' }
      it { is_expected.to eq('legacy') }
    end

    context 'when nothing is requested' do
      let(:search_engine) { nil }
      it { is_expected.to eq('new') }
    end

    context 'when an unknown engine is requested' do
      let(:search_engine) { 'quantum' }
      it { is_expected.to eq('new') }
    end
  end

  describe '#indexed_search?' do
    subject { controller.indexed_search? }

    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(search_engine: search_engine,
                                         query: query)
      )
    end

    context 'when the new engine is searching' do
      let(:search_engine) { nil }
      let(:query) { 'bob' }
      it { is_expected.to be(true) }
    end

    context 'when nothing is being searched for' do
      let(:search_engine) { nil }
      let(:query) { '' }
      it { is_expected.to be(false) }
    end

    context 'when the legacy engine is searching' do
      let(:search_engine) { 'legacy' }
      let(:query) { 'bob' }
      it { is_expected.to be(false) }
    end
  end

  describe '#measure_search' do
    let(:search_engine) { nil }
    let(:relation) { User.all.paginate(page: 1, per_page: 100) }

    it 'gathers stats for the relation' do
      controller.measure_search(relation)
      expect(controller.search_stats.count).to eq(User.count)
    end

    it 'returns the relation' do
      expect(controller.measure_search(relation)).to eq(relation)
    end
  end

  describe '#legacy_search?' do
    subject { controller.legacy_search? }

    context 'when the legacy engine is requested' do
      let(:search_engine) { 'legacy' }
      it { is_expected.to be(true) }
    end

    context 'when nothing is requested' do
      let(:search_engine) { nil }
      it { is_expected.to be(false) }
    end
  end
end
