require 'spec_helper'

RSpec.describe Search::RequestList do
  describe '#call' do
    it 'filters searchable requests by their status' do
      successful = FactoryBot.create(:info_request)
      successful.set_described_state('successful')
      waiting = FactoryBot.create(:info_request)

      result = described_class.
               new({ latest_status: 'successful' }, 1, 25, 100).call

      expect(result[:results]).to include(successful)
      expect(result[:results]).not_to include(waiting)
    end

    it 'filters searchable requests by their authority' do
      public_body = FactoryBot.create(:public_body)
      to_body = FactoryBot.create(:info_request, public_body: public_body)
      FactoryBot.create(:info_request)

      result = described_class.
               new({ public_body: public_body }, 1, 25, 100).call

      expect(result[:results]).to eq([to_body])
    end

    it 'filters searchable requests by their requester' do
      user = FactoryBot.create(:user)
      by_user = FactoryBot.create(:info_request, user: user)
      FactoryBot.create(:info_request)

      result = described_class.new({ user: user }, 1, 25, 100).call

      expect(result[:results]).to eq([by_user])
    end

    it 'filters searchable requests by their described state' do
      rejected = FactoryBot.create(:info_request)
      rejected.set_described_state('rejected')
      FactoryBot.create(:info_request)

      result = described_class.
               new({ described_state: 'rejected' }, 1, 25, 100).call

      expect(result[:results]).to eq([rejected])
    end

    it 'restricts by a free-text query through the search backend' do
      match = FactoryBot.create(:info_request)
      stub_request_search_results(items: [match])

      result = described_class.
               new({ query: 'badger', latest_status: 'all' }, 1, 25, 100).call

      expect(result[:results]).to eq([match])
    end

    context 'with a date range' do
      let!(:old) do
        FactoryBot.create(:info_request).tap do |request|
          request.info_request_events.update_all(created_at: '2000-06-01')
        end
      end
      let!(:recent) { FactoryBot.create(:info_request) }

      def list(**filters)
        described_class.new(filters, 1, 25, 100).call[:results]
      end

      %w[01/01/2000 2000/01/01 2000-01-01 01.01.2000].each do |date|
        it "reads #{date}" do
          expect(list(request_date_after: date,
                      request_date_before: '2000-12-31')).to eq([old])
        end
      end

      it 'takes an open-ended range' do
        expect(list(request_date_before: '2000-12-31')).to eq([old])
        expect(list(request_date_after: '2001-01-01')).to include(recent)
        expect(list(request_date_after: '2001-01-01')).not_to include(old)
      end

      it 'matches a request with any searchable event in the range' do
        recent.info_request_events.first.
          update_column(:created_at, '2000-06-01')

        expect(list(request_date_after: '2000-01-01',
                    request_date_before: '2000-12-31')).
          to contain_exactly(old, recent)
      end
    end

    it 'caps show_no_more_than at max_results' do
      3.times { FactoryBot.create(:info_request) }

      result = described_class.new({ latest_status: 'all' }, 1, 25, 2).call

      expect(result[:matches_estimated]).to be >= 3
      expect(result[:show_no_more_than]).to eq(2)
    end
  end
end
