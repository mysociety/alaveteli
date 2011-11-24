require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestGameController, "when playing the game" do

    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :info_request_events # all needed as integrating views
    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should show the game homepage" do
        get :play
        response.should render_template('play')
    end
end
 
