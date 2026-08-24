require 'spec_helper'

RSpec.describe Admin::SearchHelper do
  describe '#search_duration' do
    subject { helper.search_duration(seconds) }

    context 'given a fraction of a second' do
      let(:seconds) { 0.0312 }
      it { is_expected.to eq('31.2ms') }
    end

    context 'given several seconds' do
      let(:seconds) { 2.5 }
      it { is_expected.to eq('2,500.0ms') }
    end
  end

  describe '#explain_search?' do
    subject { helper.explain_search? }

    before { allow(helper).to receive(:params).and_return(explain: explain) }

    context 'when the explain param is on' do
      let(:explain) { '1' }
      it { is_expected.to be(true) }
    end

    context 'when the explain param is off' do
      let(:explain) { '0' }
      it { is_expected.to be(false) }
    end
  end

  describe '#explain_search_url' do
    subject { helper.explain_search_url(explain) }

    before do
      controller.request.path_parameters =
        { controller: 'admin_user', action: 'index' }
      controller.request.query_parameters[:query] = 'bob'
    end

    context 'switching the query plan on' do
      let(:explain) { true }
      it { is_expected.to eq('/admin/users?explain=1&query=bob') }
    end

    context 'switching the query plan off' do
      let(:explain) { false }
      it { is_expected.to eq('/admin/users?explain=0&query=bob') }
    end
  end
end
