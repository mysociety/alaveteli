# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminGeneralController do

    describe "when viewing front page of admin interface" do

        render_views
        before { basic_auth_login @request }

        it "should render the front page" do
            get :index
            response.should render_template('index')
        end

    end

    describe 'when viewing the timeline' do

        it 'should assign an array of events in order of descending date to the view' do
            get :timeline, :all => 1
            previous_event = nil
            previous_event_at = nil
            assigns[:events].each do |event, event_at|
                if previous_event
                    (event_at <= previous_event_at).should be_true
                end
                previous_event = event
                previous_event_at = event_at
            end
        end

    end
end
