require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRequestController, "when administering requests" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :users, :info_request_events
    before { basic_auth_login @request }

    it "shows the index/list page" do
        get :index
    end

    it "shows a public body" do
        get :show, :id => info_requests(:fancy_dog_request)
    end

    it "edits a public body" do
        get :edit, :id => info_requests(:fancy_dog_request)
    end

    it "saves edits to a request" do
        info_requests(:fancy_dog_request).title.should == "Why do you have & such a fancy dog?"
        post :update, { :id => info_requests(:fancy_dog_request), :info_request => { :title => "Renamed", :prominence => "normal", :described_state => "waiting_response", :awaiting_description => false, :allow_new_responses_from => 'anybody', :handle_rejected_responses => 'bounce' } }
        response.flash[:notice].should include('successful')
        ir = InfoRequest.find(info_requests(:fancy_dog_request).id)
        ir.title.should == "Renamed"
    end

    it "edits an outgoing message" do
        get :edit_outgoing, :id => outgoing_messages(:useless_outgoing_message)
    end

    it "saves edits to an outgoing_message" do
        outgoing_messages(:useless_outgoing_message).body.should include("fancy dog")
        post :update_outgoing, { :id => outgoing_messages(:useless_outgoing_message), :outgoing_message => { :body => "Why do you have such a delicious cat?" } }
        response.flash[:notice].should include('successful')
        ir = OutgoingMessage.find(outgoing_messages(:useless_outgoing_message).id)
        ir.body.should include("delicious cat")
    end

end

describe AdminRequestController, "when administering the holding pen" do
    integrate_views
    fixtures :info_requests, :incoming_messages, :raw_emails, :users, :public_bodies, :public_body_translations
    before(:each) do
        basic_auth_login @request
        load_raw_emails_data(raw_emails)
    end

    it "shows a rejection reason for an incoming message from an invalid address" do
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'authority_only'
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
        get :show_raw_email, :id => InfoRequest.holding_pen_request.get_last_response.raw_email.id
        response.should have_text(/Only the authority can reply to this request/)
    end

    it "guesses a misdirected request" do
        ir = info_requests(:fancy_dog_request)
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!
        mail_to = "request-#{ir.id}-asdfg@example.com"
        receive_incoming_mail('incoming-request-plain.email', mail_to)
        get :show_raw_email, :id => InfoRequest.holding_pen_request.get_last_response.raw_email.id
        response.should have_text(/Could not identify the request/)
        assigns[:info_requests][0].should == ir
    end

    it "destroys an incoming message" do
        im = incoming_messages(:useless_incoming_message)        
        raw_email = im.raw_email.filepath
        post :destroy_incoming, :incoming_message_id => im.id
        assert_equal File.exists?(raw_email), false        
    end

end
