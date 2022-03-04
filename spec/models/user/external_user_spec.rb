require 'spec_helper'

RSpec.describe User::ExternalUser do
  describe '#name' do
    subject { described_class.new(info_request: info_request).name }

    context 'when the request was signed' do
      let(:info_request) { double(external_user_name: 'Eve External') }
      it { is_expected.to eq('Eve External') }
    end

    context 'when the request was made anonymously' do
      let(:info_request) { double(external_user_name: nil) }
      it { is_expected.to eq('Anonymous user') }
    end
  end

  describe '#url_name' do
    subject { described_class.new(info_request: info_request).url_name }

    context 'when the request was signed' do
      let(:info_request) do
        double(external_user_name: 'Eve External',
               public_body: double(url_name: 'dfh'))
      end

      it { is_expected.to eq('dfh_eve_external') }
    end

    context 'when the request was made anonymously' do
      let(:info_request) do
        double(external_user_name: nil, public_body: double(url_name: 'dfh'))
      end

      it { is_expected.to eq('dfh_anonymous_user') }
    end

    context 'when the request was signed with a long name' do
      let(:info_request) do
        double(external_user_name: 'Eve Extra Extra Extra Extra Long External',
               public_body: double(url_name: 'dfh'))
      end

      it { is_expected.to eq('dfh_eve_extra_extra_extra_extra_long') }
    end

    context 'when the body has no url_name' do
      let(:info_request) do
        double(external_user_name: 'Eve E', public_body: double(url_name: nil))
      end

      it { is_expected.to eq('_eve_e') }
    end

    context 'when the request has no body' do
      let(:info_request) do
        double(external_user_name: 'Eddie E', public_body: nil)
      end

      it { is_expected.to eq('_eddie_e') }
    end
  end

  describe '#prominence' do
    subject { described_class.new(info_request: double).prominence }
    it { is_expected.to eq('backpage') }
  end

  describe '#censor_rules' do
    subject { described_class.new(info_request: double).censor_rules }
    it { is_expected.to be_empty }
  end

  describe '#flipper_id' do
    subject { described_class.new(info_request: double).flipper_id }
    it { is_expected.to eq('User;external') }
  end

  describe '#is_pro?' do
    subject { described_class.new(info_request: double).is_pro? }
    it { is_expected.to eq(false) }
  end

  describe '#json_for_api' do
    subject { described_class.new(info_request: info_request).json_for_api }
    let(:info_request) { double(external_user_name: 'Eddie External') }
    it { is_expected.to eq(name: 'Eddie External') }
  end

  describe '#external?' do
    subject { described_class.new(info_request: double).external? }
    it { is_expected.to eq(true) }
  end
end
