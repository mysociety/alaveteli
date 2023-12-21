require 'spec_helper'

RSpec.describe Admin::HoldingPenHelper, type: :helper do
  include Admin::HoldingPenHelper

  describe '#guess_badge' do
    subject do
      guess_badge(score) { block }
    end

    let(:score) { 0 }
    let(:block) { '<br>'.html_safe }

    it 'renders the block' do
      expect(subject).to eq(%q(<span class="badge"><br></span>))
    end

    context 'direct match' do
      let(:score) { 1 }
      it { is_expected.to match(/badge-success/) }
    end

    context 'close match' do
      (70..99).each do |score|
        let(:score) { score / 100.0 }
        it { is_expected.to match(/badge-info/) }
      end
    end

    context 'vague match' do
      (11..69).each do |score|
        let(:score) { score / 100.0 }
        it { is_expected.to match(/badge-warning/) }
      end
    end

    context 'unlikely match' do
      (1..10).each do |score|
        let(:score) { score / 100.0 }
        it { is_expected.to match(/badge-important/) }
      end
    end

    context 'no match' do
      let(:score) { 0 }
      it { is_expected.not_to match(/badge-/) }
    end
  end
end
