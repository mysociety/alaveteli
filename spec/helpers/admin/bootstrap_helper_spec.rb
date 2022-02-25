require 'spec_helper'

RSpec.describe Admin::BootstrapHelper, type: :helper do
  describe '#nav_li' do
    subject do
      helper.nav_li('/path') { 'foo' }
    end

    context 'when the path is the current page' do
      before { expect(helper).to receive(:current_page?).and_return(true) }
      it { is_expected.to eq(%q[<li class="active">foo</li>]) }
    end

    context 'when the path is not the current page' do
      before { expect(helper).to receive(:current_page?).and_return(false) }
      it { is_expected.to eq(%q[<li>foo</li>]) }
    end
  end
end
