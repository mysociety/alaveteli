require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestGameController, "when playing the game" do

    fixtures :info_requests, :info_request_events, :public_bodies, :public_body_translations, :users, :incoming_messages, :raw_emails, :outgoing_messages # all needed as integrating views
    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should show the game homepage" do
        get :play
        response.should render_template('play')
    end
end
 
