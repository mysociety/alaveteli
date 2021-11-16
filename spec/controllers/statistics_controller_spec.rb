require "spec_helper"

RSpec.describe StatisticsController do
  describe "#index" do

    before do
      allow(AlaveteliConfiguration).
        to receive(:minimum_requests_for_statistics).and_return 1
      allow(AlaveteliConfiguration).
        to receive(:public_body_statistics_page).and_return true
    end

    it "uses the date of the first public request as the start_date" do
      InfoRequest.destroy_all

      travel_to(1.week.ago) do
        FactoryBot.create(:embargoed_request)
        FactoryBot.create(:hidden_request)
      end
      expected_request = FactoryBot.create(:info_request)
      expected_request.reload

      expect(Statistics).
        to receive(:by_week_to_today_with_noughts).
          with(anything, expected_request.created_at)

      get :index
    end

    it "should render the right template with the right data" do
      get :index
      expect(response).to render_template('statistics/index')
      # There are 5 different graphs we're creating at the moment.
      expect(assigns[:public_bodies].length).to eq(5)
      # The first is the only one with raw values, the rest are
      # percentages with error bars:
      assigns[:public_bodies].each_with_index do |graph, index|
        if index == 0
          expect(graph['errorbars']).to be false
          expect(graph['x_values'].length).to eq(4)
          expect(graph['x_values']).to eq([0, 1, 2, 3])
          expect(graph['y_values']).to eq([1, 2, 2, 4])
        else
          expect(graph['errorbars']).to be true
          # Just check the first one:
          if index == 1
            expect(graph['x_values']).to eq([0, 1, 2, 3])
            expect(graph['y_values']).to eq([0, 50, 100, 100])
          end
          # Check that at least every confidence interval value is
          # a Float (rather than NilClass, say):
          graph['cis_below'].each { |v| expect(v).to be_instance_of(Float) }
          graph['cis_above'].each { |v| expect(v).to be_instance_of(Float) }
        end
      end
    end

    it 'should be able to return structured JSON data' do
      get :index, params: { format: 'json' }
      json = JSON.parse(response.body)

      expect(json['public_bodies']).to be_an(Array)
      expect(json['public_bodies'][0]).to include(
        'errorbars' => false,
        'y_values' => [1, 2, 2, 4],
        'x_values' => [0, 1, 2, 3]
      )
      expect(json['public_bodies'][1]).to include(
        'errorbars' => true,
        'x_values' => [0, 1, 2, 3],
        'y_values' => [0, 50, 100, 100]
      )
      expect(json['public_bodies'][2]).to include(
        'errorbars' => true
      )

      expect(json['users']).to be_a(Hash)
      expect(json['users'].keys).to match_array(
        %w[all_time_requesters last_28_day_requesters
           all_time_commenters last_28_day_commenters]
      )

      expect(json['requests']).to be_a(Hash)
      expect(json['requests']['hides_by_week']).to be_an(Array)
    end
  end
end
