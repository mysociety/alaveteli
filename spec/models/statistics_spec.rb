require "spec_helper"

RSpec.describe Statistics do
  describe ".public_bodies" do
    # TODO
  end

  describe ".simplify_stats_for_graphs" do
    let(:raw_count_data) do
      PublicBody.get_request_totals(n=3, highest=true, minimum_requests=1)
    end

    let(:percentages_data) do
      PublicBody.get_request_percentages(
        column='info_requests_successful_count',
        n=3,
        highest=false,
        minimum_requests=1
      )
    end

    it "should not include the real public body model instance" do
      to_draw = Statistics.simplify_stats_for_graphs(raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {} )
      expect(to_draw['public_bodies'][0].class).to eq(Hash)
      expect(to_draw['public_bodies'][0].has_key?('request_email')).to be false
    end

    it "should generate the expected id" do
      to_draw = Statistics.simplify_stats_for_graphs(raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {:highest => true} )
      expect(to_draw['id']).to eq("blah_blah-highest")
      to_draw = Statistics.simplify_stats_for_graphs(raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {:highest => false} )
      expect(to_draw['id']).to eq("blah_blah-lowest")
    end

    it "should have exactly the expected keys" do
      to_draw = Statistics.simplify_stats_for_graphs(raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {} )
      expect(to_draw.keys.sort).to eq(["errorbars", "id", "public_bodies",
                                       "title", "tooltips", "totals",
                                       "x_axis", "x_ticks", "x_values",
                                       "y_axis", "y_max", "y_values"])

      to_draw = Statistics.simplify_stats_for_graphs(percentages_data,
                                                     column='whatever',
                                                     percentages=true,
                                                     {})
      expect(to_draw.keys.sort).to eq(["cis_above", "cis_below",
                                       "errorbars", "id", "public_bodies",
                                       "title", "tooltips", "totals",
                                       "x_axis", "x_ticks", "x_values",
                                       "y_axis", "y_max", "y_values"])
    end

    it "should have values of the expected class and length" do
      [Statistics.simplify_stats_for_graphs(raw_count_data,
                                            column='blah_blah',
                                            percentages=false,
                                            {}),
       Statistics.simplify_stats_for_graphs(percentages_data,
                                            column='whatever',
                                            percentages=true,
      {})].each do |to_draw|
        per_pb_keys = ["cis_above", "cis_below", "public_bodies",
                       "tooltips", "totals", "x_ticks", "x_values",
                       "y_values"]
        # These should be all be arrays with one element per public body:
        per_pb_keys.each do |key|
          if to_draw.has_key? key
            expect(to_draw[key].class).to eq(Array)
            expect(to_draw[key].length).to eq(3), "for key #{key}"
          end
        end
        # Just check that the rest aren't of class Array:
        to_draw.keys.each do |key|
          unless per_pb_keys.include? key
            expect(to_draw[key].class).not_to eq(Array), "for key #{key}"
          end
        end
      end
    end
  end

  describe ".users" do
    it "creates a hash of user statistics" do
      allow(User).to receive(:all_time_requesters).and_return([])
      allow(User).to receive(:last_28_day_requesters).and_return([])
      allow(User).to receive(:all_time_commenters).and_return([])
      allow(User).to receive(:last_28_day_commenters).and_return([])

      expect(Statistics.users).to eql(
        {
          all_time_requesters: [],
          last_28_day_requesters: [],
          all_time_commenters: [],
          last_28_day_commenters: []
        }
      )
    end
  end

  describe ".user_json_for_api" do
    it "creates more descriptive and sanitised JSON" do
      user = FactoryBot.create(:user)
      test_data = { a_test_key: { user => 123 } }

      expect(Statistics.user_json_for_api(test_data)).to eql(
        { a_test_key: [{ user: user.json_for_api, count: 123 }] }
      )
    end
  end

  describe ".by_week_to_today_with_noughts" do
    it "adds missing weeks with noughts" do
      data = [
        [Date.parse("2016-01-04"), 2],
        [Date.parse("2016-01-18"), 1]
      ]
      date_from = Date.new(2015, 12, 28)
      fake_current_date = Date.new(2016, 1, 31)

      travel_to(fake_current_date) do
        expect(Statistics.by_week_to_today_with_noughts(data, date_from)).to eql(
          [
            ["2015-12-28", 0],
            ["2016-01-04", 2],
            ["2016-01-11", 0],
            ["2016-01-18", 1],
            ["2016-01-25", 0]
          ]
        )
      end
    end
  end
end
