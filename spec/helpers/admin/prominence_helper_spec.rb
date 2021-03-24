require 'spec_helper'

describe Admin::ProminenceHelper, type: :helper do
  describe '#prominence_icon' do
    subject { helper.prominence_icon(prominence) }

    %i[normal backpage requester_only hidden].each do |prominence|
      let(prominence) { double(prominence: prominence.to_s) }
    end

    context 'when given a string' do
      let(:prominence) { 'normal' }
      it { is_expected.to eq(helper.prominence_icon(normal)) }
    end

    context 'normal' do
      let(:prominence) { normal }
      it { is_expected.to include(%q(title="normal")) }
      it { is_expected.to include('icon-prominence--normal') }
    end

    context 'backpage' do
      let(:prominence) { backpage }
      it { is_expected.to include(%q(title="backpage")) }
      it { is_expected.to include('icon-prominence--backpage') }
    end

    context 'requester_only' do
      let(:prominence) { requester_only }
      it { is_expected.to include(%q(title="requester_only")) }
      it { is_expected.to include('icon-prominence--requester_only') }
    end

    context 'hidden' do
      let(:prominence) { hidden }
      it { is_expected.to include(%q(title="hidden")) }
      it { is_expected.to include('icon-prominence--hidden') }
    end
  end
end
