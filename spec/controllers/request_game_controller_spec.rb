require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestGameController, "when playing the game" do

    fixtures :public_bodies, :public_body_translations, :public_body_versions, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events, :track_things # all needed as integrating views
    before(:each) do
        load_raw_emails_data
    end

    it "should show the game homepage" do
        get :play
        response.should render_template('play')
    end
end
 
