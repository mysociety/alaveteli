require 'spec_helper'

RSpec.describe RefusalAdviceQuestionForm do
  let(:builder) { described_class.new(:refusal_advice, resource, template, {}) }
  let(:template) { self }

  let(:resource) { double(id: 'confirm-or-deny', options: options) }
  let(:options) { [option] }
  let(:option) { double(value: 'yes', label: 'Yes') }

  describe '#wizard_option' do
    subject { builder.wizard_option(option) }

    it { is_expected.to match(/id="confirm-or-deny_yes"/) }
    it { is_expected.to match(/name="refusal_advice"/) }
    it { is_expected.to match(/value="yes"/) }
    it { is_expected.to match(/for="confirm-or-deny_yes"/) }
    it { is_expected.to match(/Yes/) }

    context 'two or fewer options' do
      let(:options) { [option, option] }
      it { is_expected.to match(/radio/) }
    end

    context 'more than two options' do
      let(:options) { [option, option, option] }
      it { is_expected.to match(/checkbox/) }
    end
  end

  describe '#wizard_options_class' do
    subject { builder.wizard_options_class(options) }
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
