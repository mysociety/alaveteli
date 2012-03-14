require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRequestController, "when administering requests" do
    integrate_views
    before { basic_auth_login @request }

    before(:each) do
        load_raw_emails_data
        @old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
    end
    after do
        ActionController::Routing::Routes.filters = @old_filters
    end

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
    before(:each) do
        basic_auth_login @request
        load_raw_emails_data
        @old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
    end
    after do
        ActionController::Routing::Routes.filters = @old_filters
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

    it "allows redelivery even to a closed request" do
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'nobody'
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!
        InfoRequest.holding_pen_request.incoming_messages.length.should == 0
        ir.incoming_messages.length.should == 1
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
        InfoRequest.holding_pen_request.incoming_messages.length.should == 1
        new_im = InfoRequest.holding_pen_request.incoming_messages[0]
        ir.incoming_messages.length.should == 1
        post :redeliver_incoming, :redeliver_incoming_message_id => new_im.id, :url_title => ir.url_title        
        ir = InfoRequest.find_by_url_title(ir.url_title)
        ir.incoming_messages.length.should == 2
        response.should redirect_to(:controller=>'admin_request', :action=>'show', :id=>101)
        InfoRequest.holding_pen_request.incoming_messages.length.should == 0
    end

    it "guesses a misdirected request" do
        ir = info_requests(:fancy_dog_request)
        ir.handle_rejected_responses = 'holding_pen'
        ir.allow_new_responses_from = 'authority_only'
        ir.save!
        mail_to = "request-#{ir.id}-asdfg@example.com"
        receive_incoming_mail('incoming-request-plain.email', mail_to)
        interesting_email = InfoRequest.holding_pen_request.get_last_response.raw_email.id
        # now we add another message to the queue, which we're not interested in
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
        InfoRequest.holding_pen_request.incoming_messages.length.should == 2
        get :show_raw_email, :id => interesting_email
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
