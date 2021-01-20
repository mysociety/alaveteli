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
end
