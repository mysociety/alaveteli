require 'spec_helper'

RSpec.describe InfoRequestBatchMetrics do
  describe '#metrics' do
    let(:batch) { FactoryBot.create(:info_request_batch, :sent) }
    let(:request) { batch.info_requests.first }

    subject(:metrics) { described_class.new(batch).metrics }

    it 'generates info request batch metrics' do
      request_url = 'http://test.host/en/alaveteli_pro/info_requests/' +
                    request.url_title
      authority_name = request.public_body.name

      is_expected.to match_array(
        [
          { request_url: request_url, authority_name: authority_name,
            number_of_replies: 0, request_status: 'Awaiting response' }
        ]
      )
    end

    context 'when batch info request has responses' do
      before do
        FactoryBot.create(:incoming_message, info_request: request)
      end

      it 'generates info request batch metrics' do
        expect(metrics.first[:number_of_replies]).to eq 1
      end
    end

    context 'when batch info request has the status updated' do
      before do
        request.set_described_state('waiting_clarification')
      end

      it 'generates info request batch metrics' do
        expect(metrics.first[:request_status]).to eq 'Awaiting clarification'
      end
    end
  end

  describe '#name' do
    let(:batch) { double(:info_request_batch, id: 1, title: 'Batch Request') }
    subject(:name) { described_class.new(batch).name }

    it 'returns a useful filename' do
      time_travel_to Time.utc(2019, 11, 18, 10, 30)
      is_expected.to(
        eq 'batch-1-batch_request-dashboard-2019-11-18-103000.csv'
      )
      back_to_the_present
    end
  end

  describe '#to_csv' do
    let(:batch) { double(:info_request_batch) }
    let(:instance) { described_class.new(batch) }
    subject { instance.to_csv }

    it 'returns CSV string from metrics' do
      allow(instance).to receive(:metrics).and_return(
        [{ foo: 'Foo', bar: 'Bar' }]
      )

      is_expected.to eq <<~CSV
        foo,bar
        Foo,Bar
      CSV
    end
  end
end
