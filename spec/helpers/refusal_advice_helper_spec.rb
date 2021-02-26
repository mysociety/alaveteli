require 'spec_helper'

describe RefusalAdviceHelper do
  include RefusalAdviceHelper

  describe '#refusal_advice_actionable?' do
    subject { refusal_advice_actionable?(action, info_request: info_request) }
    let(:info_request) { nil }
    let(:current_user) { FactoryBot.build(:user) }

    context 'internal action, info_request' do
      let(:action) { double(target: { internal: 'followup' }) }
      let(:info_request) { FactoryBot.build(:info_request, user: current_user) }
      it { is_expected.to eq true }
    end

    context 'internal action, other info request' do
      let(:action) { double(target: { internal: 'followup' }) }
      let(:info_request) { FactoryBot.build(:info_request) }
      it { is_expected.to eq false }
    end

    context 'internal action, no info_request' do
      let(:action) { double(target: { internal: 'followup' }) }
      let(:info_request) { nil }
      it { is_expected.to eq false }
    end

    context 'help_page action' do
      let(:action) { double(target: { help_page: 'ico' }) }
      it { is_expected.to eq true }
    end

    context 'external action' do
      let(:action) { double(target: { external: 'http://...' }) }
      it { is_expected.to eq true }
    end
  end
end
