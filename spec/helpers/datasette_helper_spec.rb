require 'spec_helper'

RSpec.describe DatasetteHelper do
  include DatasetteHelper

  describe '#explore_in_datasette' do
    subject { explore_in_datasette(attachment) }

    let(:info_request) { FactoryBot.build(:info_request) }

    let(:incoming_message) do
      FactoryBot.build(:incoming_message, info_request: info_request)
    end

    let(:csv) do
      FactoryBot.create(:csv_attachment, incoming_message: incoming_message)
    end

    context 'the attachment is a CSV' do
      let(:attachment) { csv }

      let(:expected) do
        url = ERB::Util.url_encode(attachment_url(attachment))
        url = "https://lite.datasette.io/?csv=#{url}"
        link_to 'Explore in Datasette', url
      end

      it { is_expected.to eq(expected) }

      context 'with a custom datasette instance' do
        around do |example|
          default = DatasetteHelper.datasette_url
          DatasetteHelper.datasette_url = 'https://d.example.com/'
          example.run
          DatasetteHelper.datasette_url = default
        end

        it { is_expected.to include('https://d.example.com/?csv=http') }
      end
    end

    context 'the attachment is not public' do
      let(:attachment) { csv }
      before { attachment.prominence = 'hidden' }
      it { is_expected.to be_nil }
    end

    context 'the incoming message is not public' do
      let(:attachment) { csv }
      before { incoming_message.prominence = 'hidden' }
      it { is_expected.to be_nil }
    end

    context 'the info request is not public' do
      let(:attachment) { csv }
      before { info_request.prominence = 'hidden' }
      it { is_expected.to be_nil }
    end

    context 'the attachment is not a CSV' do
      let(:attachment) do
        FactoryBot.build(:rtf_attachment, incoming_message: incoming_message)
      end

      it { is_expected.to be_nil }
    end
  end
end
