require 'spec_helper'

describe RefusalAdviceHelper do
  include RefusalAdviceHelper

  describe '#refusal_advice_radio' do
    subject { refusal_advice_radio(question, option) }

    let(:question) { double(id: 'confirm-or-deny') }
    let(:option) { double(value: 'yes', label: 'Yes') }

    it { is_expected.to match(/radio/) }
    it { is_expected.to match(/name="confirm-or-deny"/) }
    it { is_expected.to match(/id="confirm-or-deny_yes"/) }
    it { is_expected.to match(/value="yes"/) }
    it { is_expected.to match(/for="confirm-or-deny_yes"/) }
    it { is_expected.to match(/Yes/) }
  end

  describe '#refusal_advice_checkbox' do
    subject { refusal_advice_checkbox(question, option) }

    let(:question) { double(id: 'refusal-reasons') }
    let(:option) { double(value: 'section-1', label: 'Section 1') }

    it { is_expected.to match(/checkbox/) }
    it { is_expected.to match(/name="refusal-reasons"/) }
    it { is_expected.to match(/id="refusal-reasons_section-1"/) }
    it { is_expected.to match(/value="section-1"/) }
    it { is_expected.to match(/for="refusal-reasons_section-1"/) }
    it { is_expected.to match(/Section 1/) }
  end
end
