require 'spec_helper'

RSpec.describe ClassificationsHelper do
  include ClassificationsHelper

  describe '#classification_radio_button' do
    subject { classification_radio_button(state, id_suffix: id_suffix) }

    let(:state) { 'successful' }
    let(:id_suffix) { nil }

    it 'builds a radio_button for the given state' do
      html = <<-HTML.squish
      <input id="successful"
             type="radio"
             value="successful"
             name="classification[described_state]" />
      HTML

      expect(subject).to eq(html)
    end

    context 'with an id_suffix' do
      let(:id_suffix) { 3 }
      it { is_expected.to match('id="successful3"') }
    end
  end

  describe '#classification_label' do
    subject { classification_label(state, text, id_suffix: id_suffix) }

    let(:state) { 'successful' }
    let(:text) { 'All the information was sent' }
    let(:id_suffix) { nil }

    it 'builds a label for the given field' do
      html = %q(<label for="successful">All the information was sent</label>)
      expect(subject).to eq(html)
    end

    context 'with an id_suffix' do
      let(:id_suffix) { 3 }
      it { is_expected.to match('for="successful3"') }
    end
  end

  describe '#user_classification_milestone?' do
    subject { user_classification_milestone?(classifications) }

    context 'when the count is below a milestone' do
      let(:classifications) { 99 }
      it { is_expected.to eq(false) }
    end

    context 'when the count is at a milestone' do
      let(:classifications) { 100 }
      it { is_expected.to eq(true) }
    end

    context 'when the count is above a milestone' do
      let(:classifications) { 101 }
      it { is_expected.to eq(false) }
    end
  end
end
