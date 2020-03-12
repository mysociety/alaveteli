require 'spec_helper'

RSpec.describe InfoRequestBatchZip do
  ZippableFile = described_class::ZippableFile

  let(:batch) do
    FactoryBot.create(:info_request_batch, info_requests: [request])
  end
  let(:request) { FactoryBot.build(:info_request) }

  describe '#files' do
    subject(:files) { described_class.new(batch).files }
    let(:paths) { files.map(&:path) }

    let(:base_path) do
      [request.public_body.name, request.url_title].join(' - ')
    end

    before do
      # stub metrics service
      allow(InfoRequestBatchMetrics).to receive(:new).with(batch).
        and_return(double(:metrics, name: 'NAME', to_csv: 'CSV_DATA'))
    end

    around do |example|
      time_travel_to Time.utc(2019, 11, 18, 10, 30)
      example.call
      back_to_the_present
    end

    it 'generates list of zippable files' do
      is_expected.to all(be_a ZippableFile)
    end

    it 'includes batch metrics at the root' do
      is_expected.to include(ZippableFile.new('NAME', 'CSV_DATA'))
    end

    context 'when batch info request has been sent' do
      let(:event) { FactoryBot.create(:sent_event, info_request: request) }
      let!(:message) { event.outgoing_message }

      it 'includes outgoing message' do
        expect(paths).to include(
          "#{base_path}/2019-11-04-103000/outgoing_#{message.id}.txt"
        )
      end
    end

    context 'when batch info request has responses' do
      let(:event) { FactoryBot.create(:response_event, info_request: request) }
      let!(:message) { event.incoming_message }

      it 'includes incoming message' do
        expect(paths).to include(
          "#{base_path}/2019-11-11-103000/incoming_#{message.id}.txt"
        )
      end
    end

    context 'when batch info request has attachments' do
      let(:event) do
        FactoryBot.create(
          :response_event, :with_attachments, info_request: request
        )
      end

      let(:message) { event.incoming_message }
      let!(:attachment) { message.foi_attachments.first }

      it 'includes attachments' do
        expect(paths).to include(
          "#{base_path}/2019-11-11-103000/attachments/#{attachment.filename}"
        )
      end
    end
  end

  describe '#name' do
    let(:batch) { double(:info_request_batch, id: 1, title: 'Batch Request') }
    subject(:name) { described_class.new(batch).name }

    it 'returns a useful filename' do
      time_travel_to Time.utc(2019, 11, 18, 10, 30)
      is_expected.to(
        eq 'batch-1-batch_request-export-2019-11-18-103000.zip'
      )
      back_to_the_present
    end
  end
end
