# == Schema Information
#
# Table name: citations
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  citable_type :string
#  citable_id   :integer
#  source_url   :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

def setup_for_x_scope_data
  # Citations on InfoRequestBatch and InfoRequests within the batch: A
  let!(:batch_a) do
    FactoryBot.create(:info_request_batch, :sent, public_body_count: 2)
  end

  let!(:batch_a_info_request_a) { batch_a.info_requests.first }
  let!(:batch_a_info_request_b) { batch_a.info_requests.last }

  let!(:citation_batch_a) do
    FactoryBot.create(:citation, citable: batch_a)
  end

  let!(:citation_batch_a_request_a) do
    FactoryBot.create(:citation, citable: batch_a_info_request_a)
  end

  # Citations on InfoRequestBatch only: B
  let!(:batch_b) do
    FactoryBot.create(:info_request_batch, :sent, public_body_count: 1)
  end

  let!(:citation_batch_b) do
    FactoryBot.create(:citation, citable: batch_b)
  end

  # Citations on single InfoRequest: C
  let!(:info_request_c) { FactoryBot.create(:info_request) }

  let!(:citation_info_request_c) do
    FactoryBot.create(:citation, citable: info_request_c)
  end

  # Batch and Requests: X
  # Unused, but required to ensure we're not finding incorrect citations
  let!(:batch_x) do
    FactoryBot.create(:info_request_batch, :sent)
  end

  let!(:batch_x_info_request_a) { batch_x.info_requests.first }

  let!(:citation_batch_x) do
    FactoryBot.create(:citation, citable: batch_x)
  end

  let!(:citation_batch_x_request_a) do
    FactoryBot.create(:citation, citable: batch_x_info_request_a)
  end
end

RSpec.describe Citation, type: :model do
  describe '.for_request' do
    subject { described_class.for_request(info_request) }

    setup_for_x_scope_data

    context 'for requests that have a citation plus a batch citation' do
      let(:info_request) { batch_a_info_request_a }

      it do
        is_expected.
          to match_array([citation_batch_a, citation_batch_a_request_a])
      end
    end

    context 'for requests that only have a batch citation' do
      let(:info_request) { batch_a_info_request_b }
      it { is_expected.to match_array([citation_batch_a]) }
    end

    context 'for single requests' do
      let(:info_request) { info_request_c }
      it { is_expected.to match_array([citation_info_request_c]) }
    end
  end

  describe '.for_batch' do
    subject { described_class.for_batch(info_request_batch) }

    setup_for_x_scope_data

    context 'with a batch that has citations on the batch and its requests' do
      let(:info_request_batch) { batch_a }

      it do
        is_expected.
          to match_array([citation_batch_a, citation_batch_a_request_a])
      end
    end

    context 'with a batch that only has citations on the batch' do
      let(:info_request_batch) { batch_b }
      it { is_expected.to match_array([citation_batch_b]) }
    end
  end

  subject(:citation) { FactoryBot.build(:citation) }

  describe 'associations' do
    it 'belongs to a user' do
      expect(citation.user).to be_a User
    end

    context 'when info request cited' do
      let(:citation) { FactoryBot.build(:citation, :for_info_request) }

      it 'belongs to a info request via polymorphic citable' do
        expect(citation.citable).to be_a InfoRequest
      end
    end

    context 'when info request batch cited' do
      let(:citation) { FactoryBot.build(:citation, :for_info_request_batch) }

      it 'belongs to a info request via polymorphic citable' do
        expect(citation.citable).to be_a InfoRequestBatch
      end
    end
  end
end
