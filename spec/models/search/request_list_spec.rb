require 'spec_helper'

RSpec.describe Search::RequestList do
  describe '#call' do
    it 'filters searchable requests by their status' do
      successful = FactoryBot.create(:info_request)
      successful.set_described_state('successful')
      waiting = FactoryBot.create(:info_request)

      result = described_class.
               new({ latest_status: 'successful' }, 1, 25, 100).call

      expect(result).to include(successful)
      expect(result).not_to include(waiting)
    end

    it 'filters by a status view a theme adds' do
      appealed = FactoryBot.create(:info_request)
      appealed.update_column(:described_state, 'appealed')
      FactoryBot.create(:info_request)

      themed = Class.new(described_class) do
        def status_states
          super.merge('appealed' => %w[appealed])
        end
      end
      list = themed.new({ latest_status: 'appealed' }, 1, 25, 100)

      expect(list.call).to eq([appealed])
    end

    it 'restricts by a free-text query through the search backend' do
      match = FactoryBot.create(:info_request)
      stub_request_search_results(items: [match])

      result = described_class.
               new({ query: 'badger', latest_status: 'all' }, 1, 25, 100).call

      expect(result).to eq([match])
    end

    it 'searches only the filtered requests', :postgresql, :reindex_inline do
      FactoryBot.create(:info_request, title: 'Ptarmigan ptarmigan')
      tagged = FactoryBot.create(:info_request, title: 'Ptarmigan',
                                                tag_string: 'bird:grouse')

      result = described_class.new(
        { tag: 'bird:grouse', query: 'ptarmigan' }, 1, 25, 1
      ).call

      expect(result).to eq([tagged])
    end

    context 'with a date range' do
      let!(:old) do
        FactoryBot.create(:info_request).tap do |request|
          request.info_request_events.update_all(created_at: '2000-06-01')
        end
      end
      let!(:recent) { FactoryBot.create(:info_request) }

      def list(**filters)
        described_class.new(filters, 1, 25, 100).call
      end

      %w[01/06/2000 2000/06/01 2000-06-01 01.06.2000].each do |date|
        it "reads #{date}" do
          expect(list(request_date_after: '2000-05-31',
                      request_date_before: date)).to eq([old])
        end
      end

      it 'reads the date format of the locale' do
        AlaveteliLocalization.set_locales('en en_US', 'en')
        AlaveteliLocalization.with_locale('en_US') do
          expect(list(request_date_after: '05/31/2000',
                      request_date_before: '06/02/2000')).to eq([old])
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

    it 'returns one page, counting every match' do
      3.times { FactoryBot.create(:info_request) }

      result = described_class.new({ latest_status: 'all' }, 1, 2, 100).call

      expect(result.size).to eq(2)
      expect(result.total_entries).to be >= 3
    end
  end
end
