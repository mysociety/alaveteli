require "spec_helper"

describe Statistics do
  describe ".simplify_stats_for_graphs" do
    before(:each) do
      @raw_count_data = PublicBody.get_request_totals(n=3,
                                                      highest=true,
                                                      minimum_requests=1)
      @percentages_data = PublicBody.get_request_percentages(
        column='info_requests_successful_count',
        n=3,
        highest=false,
      minimum_requests=1)
    end

    it "should not include the real public body model instance" do
      to_draw = Statistics.simplify_stats_for_graphs(@raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {} )
      expect(to_draw['public_bodies'][0].class).to eq(Hash)
      expect(to_draw['public_bodies'][0].has_key?('request_email')).to be false
    end

    it "should generate the expected id" do
      to_draw = Statistics.simplify_stats_for_graphs(@raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {:highest => true} )
      expect(to_draw['id']).to eq("blah_blah-highest")
      to_draw = Statistics.simplify_stats_for_graphs(@raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {:highest => false} )
      expect(to_draw['id']).to eq("blah_blah-lowest")
    end

    it "should have exactly the expected keys" do
      to_draw = Statistics.simplify_stats_for_graphs(@raw_count_data,
                                                     column='blah_blah',
                                                     percentages=false,
                                                     {} )
      expect(to_draw.keys.sort).to eq(["errorbars", "id", "public_bodies",
                                       "title", "tooltips", "totals",
                                       "x_axis", "x_ticks", "x_values",
                                       "y_axis", "y_max", "y_values"])

      to_draw = Statistics.simplify_stats_for_graphs(@percentages_data,
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
      [Statistics.simplify_stats_for_graphs(@raw_count_data,
                                            column='blah_blah',
                                            percentages=false,
                                            {}),
       Statistics.simplify_stats_for_graphs(@percentages_data,
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
end
