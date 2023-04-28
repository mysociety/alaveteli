RSpec.shared_examples 'info_request/batch_pagination' do
  describe '#next_in_batch' do
    subject { info_request.next_in_batch }

    let(:batch) do
      FactoryBot.create(:info_request_batch, :sent, public_body_count: 2)
    end

    context 'the request is not part of a batch' do
      let(:info_request) { FactoryBot.build(:info_request) }
      it { is_expected.to be_nil }
    end

    context 'the request is part of a batch' do
      let(:info_request) { batch.info_requests.first }
      it { is_expected.to eq(batch.info_requests.last) }
    end

    context 'the request is the last of a batch' do
      let(:info_request) { batch.info_requests.last }
      it { is_expected.to eq(batch.info_requests.first) }
    end
  end

  describe '#prev_in_batch' do
    subject { info_request.prev_in_batch }

    let(:batch) do
      FactoryBot.create(:info_request_batch, :sent, public_body_count: 2)
    end

    context 'the request is not part of a batch' do
      let(:info_request) { FactoryBot.build(:info_request) }
      it { is_expected.to be_nil }
    end

    context 'the request is part of a batch' do
      let(:info_request) { batch.info_requests.last }
      it { is_expected.to eq(batch.info_requests.first) }
    end

    context 'the request is the first of a batch' do
      let(:info_request) { batch.info_requests.first }
      it { is_expected.to eq(batch.info_requests.last) }
    end
  end
end
