require "spec_helper"

describe StatisticsController do
  describe "#index" do
    it "should render the right template with the right data" do
      config = MySociety::Config.load_default
      config['MINIMUM_REQUESTS_FOR_STATISTICS'] = 1
      config['PUBLIC_BODY_STATISTICS_PAGE'] = true
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
  end
end
