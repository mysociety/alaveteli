# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ClassificationsHelper do
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
end
