# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AnalyticsHelper do

  include AnalyticsHelper

  describe "#track_analytics_event" do
    it "returns correctly formatted event javascript" do
      expect(track_analytics_event(
        AnalyticsEvent::Category::OUTBOUND,
        AnalyticsEvent::Action::FACEBOOK_EXIT
      )).to eq(
        "if (ga) { ga('send','event'," \
        "'Outbound Link','Facebook Exit') };"
      )
    end

    context "when supplied option values" do
      it "includes any supplied :label option string" do
        expect(track_analytics_event(
          AnalyticsEvent::Category::OUTBOUND,
          AnalyticsEvent::Action::FACEBOOK_EXIT,
          :label => "test label"
        )).to eq(
          "if (ga) { ga('send','event'," \
          "'Outbound Link','Facebook Exit','test label',1) };"
        )
      end

      it "uses 1 as the default for value if no :value option supplied" do
        expect(track_analytics_event(
          AnalyticsEvent::Category::OUTBOUND,
          AnalyticsEvent::Action::FACEBOOK_EXIT,
          :label => "test label"
        )).to eq(
          "if (ga) { ga('send','event'," \
          "'Outbound Link','Facebook Exit','test label',1) };"
        )
      end

      it "uses the supplied :value option if there is one" do
        expect(track_analytics_event(
          AnalyticsEvent::Category::OUTBOUND,
          AnalyticsEvent::Action::FACEBOOK_EXIT,
          :label => "test label",
          :value => 42
        )).to eq(
          "if (ga) { ga('send','event'," \
          "'Outbound Link','Facebook Exit','test label',42) };"
        )
      end

      it "treats the label as raw JavaScript if passed :label_is_script=true" do
        expect(track_analytics_event(
          AnalyticsEvent::Category::WIDGET_CLICK,
          AnalyticsEvent::Action::WIDGET_VOTE,
          :label => "location.href",
          :label_is_script => true
        )).to eq(
          "if (ga) { ga('send','event'," \
          "'Widget Clicked','Vote',location.href,1) };"
        )
      end

      it "ignores the :value option unless a :label option is supplied" do
        expect(track_analytics_event(
          AnalyticsEvent::Category::OUTBOUND,
          AnalyticsEvent::Action::FACEBOOK_EXIT,
          :value => 1234567
        )).not_to include("1234567")
      end

      it "raises an ArgumentError if the :value option is not an Integer" do
        expect {
          track_analytics_event(
            AnalyticsEvent::Category::OUTBOUND,
            AnalyticsEvent::Action::FACEBOOK_EXIT,
            :label => 'test label',
            :value => "five")
        }.to raise_error(
          ArgumentError, ':value option must be an Integer: "five"')
      end

    end

  end

end
