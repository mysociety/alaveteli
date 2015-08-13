# -*- encoding : utf-8 -*-
require 'confidence_intervals'

describe "ci_bounds" do

  describe "when passed all successes" do
    it "should never return a high CI above 1" do
      ci = ci_bounds 16, 16, 0.01
      expect(ci[1]).to be <= 1
    end
  end

  describe "when passed all failures" do
    it "should never return a low CI below 0" do
      ci = ci_bounds 0, 10, 0.05
      expect(ci[0]).to be >= 0
    end
  end

  describe "when passed 4 out of 10 successes (with 0.05 power)" do
    it "should return the correct Wilson's interval" do
      # The expected results here were taken from an online
      # calculator:
      #   http://www.vassarstats.net/prop1.html
      ci = ci_bounds 7, 10, 0.05
      expect(ci[0]).to be_within(0.001).of(0.3968)
      expect(ci[1]).to be_within(0.001).of(0.8922)
    end
  end

end
