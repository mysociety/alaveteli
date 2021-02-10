require 'spec_helper'

describe RefusalAdviceHelper do
  include RefusalAdviceHelper

  describe '#refusal_advice_question' do
    subject { refusal_advice_question(question, option, f: form_builder) }

    let(:form_builder) { double(:form_builder, object_name: 'refusal-advice') }
    let(:question) { double(id: 'confirm-or-deny', options: options) }
    let(:options) { [option] }
    let(:option) { double(value: 'yes', label: 'Yes') }

    it { is_expected.to match(/id="confirm-or-deny_yes"/) }
    it { is_expected.to match(/value="yes"/) }
    it { is_expected.to match(/for="confirm-or-deny_yes"/) }
    it { is_expected.to match(/Yes/) }

    context 'with form_builder' do
      it { is_expected.to match(/name="refusal-advice"/) }
    end

    context 'without form_builder' do
      subject { refusal_advice_question(question, option) }
      it { is_expected.to match(/name="confirm-or-deny"/) }
    end

    context 'two or fewer options' do
      let(:options) { [option, option] }
      it { is_expected.to match(/radio/) }
    end

    context 'more than two options' do
      let(:options) { [option, option, option] }
      it { is_expected.to match(/checkbox/) }
    end
  end

  describe '#wizard_option_class' do
    subject { wizard_option_class(options) }
    let(:option) { double(value: 'yes', label: 'Yes') }

    context 'two or fewer options' do
      let(:options) { [option, option] }
      it { is_expected.to eq 'wizard__options--list' }
    end

    context 'more than two options' do
      let(:options) { [option, option, option] }
      it { is_expected.to eq 'wizard__options--grid' }
    end
  end

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
