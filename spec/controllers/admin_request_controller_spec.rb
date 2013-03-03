require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRequestController, "when administering requests" do
    render_views
    before { basic_auth_login @request }

    before(:each) do
        load_raw_emails_data
    end

    it "shows the index/list page" do
        get :index
    end

    it "shows a public body" do
        get :show, :id => info_requests(:fancy_dog_request)
    end

    it 'shows an external public body with no username' do
        get :show, :id => info_requests(:anonymous_external_request)
        response.should be_success
    end

    it "edits a public body" do
        get :edit, :id => info_requests(:fancy_dog_request)
    end

    it "saves edits to a request" do
        info_requests(:fancy_dog_request).title.should == "Why do you have & such a fancy dog?"
        post :update, { :id => info_requests(:fancy_dog_request),
                        :info_request => { :title => "Renamed",
                                           :prominence => "normal",
                                           :described_state => "waiting_response",
                                           :awaiting_description => false,
                                           :allow_new_responses_from => 'anybody',
                                           :handle_rejected_responses => 'bounce' } }
        request.flash[:notice].should include('successful')
        ir = InfoRequest.find(info_requests(:fancy_dog_request).id)
        ir.title.should == "Renamed"
    end

    it 'expires the request cache when saving edits to it' do
        info_request = info_requests(:fancy_dog_request)
        @controller.should_receive(:expire_for_request).with(info_request)
        post :update, { :id => info_request,
                        :info_request => { :title => "Renamed",
                                           :prominence => "normal",
                                           :described_state => "waiting_response",
                                           :awaiting_description => false,
                                           :allow_new_responses_from => 'anybody',
                                           :handle_rejected_responses => 'bounce' } }

    end

    it "edits an outgoing message" do
        get :edit_outgoing, :id => outgoing_messages(:useless_outgoing_message)
    end

    it "saves edits to an outgoing_message" do
        outgoing_messages(:useless_outgoing_message).body.should include("fancy dog")
        post :update_outgoing, { :id => outgoing_messages(:useless_outgoing_message), :outgoing_message => { :body => "Why do you have such a delicious cat?" } }
        request.flash[:notice].should include('successful')
        ir = OutgoingMessage.find(outgoing_messages(:useless_outgoing_message).id)
        ir.body.should include("delicious cat")
    end

    describe 'when fully destroying a request' do

        it 'expires the file cache for that request' do
            info_request = info_requests(:badger_request)
            @controller.should_receive(:expire_for_request).with(info_request)
            get :fully_destroy, { :id => info_request }
        end

    end

end

describe AdminRequestController, "when administering the holding pen" do
    render_views
    before(:each) do
        basic_auth_login @request
        load_raw_emails_data
    end

    it "shows a rejection reason for an incoming message from an invalid address" do
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'authority_only'
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
        get :show_raw_email, :id => InfoRequest.holding_pen_request.get_last_response.raw_email.id
        response.should contain "Only the authority can reply to this request"
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

    it "allows redelivery to more than one request" do
        ir1 = info_requests(:fancy_dog_request)
        ir1.allow_new_responses_from = 'nobody'
        ir1.handle_rejected_responses = 'holding_pen'
        ir1.save!
        ir1.incoming_messages.length.should == 1
        ir2 = info_requests(:another_boring_request)
        ir2.incoming_messages.length.should == 1

        receive_incoming_mail('incoming-request-plain.email', ir1.incoming_email, "frob@nowhere.com")
        InfoRequest.holding_pen_request.incoming_messages.length.should == 1

        new_im = InfoRequest.holding_pen_request.incoming_messages[0]
        post :redeliver_incoming, :redeliver_incoming_message_id => new_im.id, :url_title => "#{ir1.url_title},#{ir2.url_title}"
        ir1.reload
        ir1.incoming_messages.length.should == 2
        ir2.reload
        ir2.incoming_messages.length.should == 2
        response.should redirect_to(:controller=>'admin_request', :action=>'show', :id=>ir2.id)
        InfoRequest.holding_pen_request.incoming_messages.length.should == 0
    end

    it 'expires the file cache for the previous request' do
        current_info_request = info_requests(:fancy_dog_request)
        destination_info_request = info_requests(:naughty_chicken_request)
        incoming_message = incoming_messages(:useless_incoming_message)
        @controller.should_receive(:expire_for_request).with(current_info_request)
        post :redeliver_incoming, :redeliver_incoming_message_id => incoming_message.id,
                                  :url_title => destination_info_request.url_title
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
        response.should contain "Could not identify the request"
        assigns[:info_requests][0].should == ir
    end

    describe 'when destroying an incoming message' do

        before do
            @im = incoming_messages(:useless_incoming_message)
            @controller.stub!(:expire_for_request)
        end

        it "destroys the raw email file" do
            raw_email = @im.raw_email.filepath
            assert_equal File.exists?(raw_email), true
            post :destroy_incoming, :incoming_message_id => @im.id
            assert_equal File.exists?(raw_email), false
        end

        it 'asks the incoming message to fully destroy itself' do
            IncomingMessage.stub!(:find).and_return(@im)
            @im.should_receive(:fully_destroy)
            post :destroy_incoming, :incoming_message_id => @im.id
        end

        it 'expires the file cache for the associated info_request' do
            @controller.should_receive(:expire_for_request).with(@im.info_request)
            post :destroy_incoming, :incoming_message_id => @im.id
        end

    end

    it "shows a suitable default 'your email has been hidden' message" do
        ir = info_requests(:fancy_dog_request)
        get :show, :id => ir.id
        assigns[:request_hidden_user_explanation].should include(ir.user.name)
        assigns[:request_hidden_user_explanation].should include("vexatious")
        get :show, :id => ir.id, :reason => "not_foi"
        assigns[:request_hidden_user_explanation].should_not include("vexatious")
        assigns[:request_hidden_user_explanation].should include("not a valid FOI")
    end

    describe 'when hiding requests' do

        it "hides requests and sends a notification email that it has done so" do
            ir = info_requests(:fancy_dog_request)
            post :hide_request, :id => ir.id, :explanation => "Foo", :reason => "vexatious"
            ir.reload
            ir.prominence.should == "requester_only"
            ir.described_state.should == "vexatious"
            deliveries = ActionMailer::Base.deliveries
            deliveries.size.should == 1
            mail = deliveries[0]
            mail.body.should =~ /Foo/
        end

        it 'expires the file cache for the request' do
            ir = info_requests(:fancy_dog_request)
            @controller.should_receive(:expire_for_request).with(ir)
            post :hide_request, :id => ir.id, :explanation => "Foo", :reason => "vexatious"
        end

        describe 'when hiding an external request' do

            before do
                @controller.stub!(:expire_for_request)
                @info_request = mock_model(InfoRequest, :prominence= => nil,
                                                        :log_event => nil,
                                                        :set_described_state => nil,
                                                        :save! => nil,
                                                        :user => nil,
                                                        :user_name => 'External User',
                                                        :is_external? => true)
                InfoRequest.stub!(:find).with(@info_request.id.to_s).and_return(@info_request)
                @default_params = { :id => @info_request.id,
                                    :explanation => 'Foo',
                                    :reason => 'vexatious' }
            end

            def make_request(params=@default_params)
                post :hide_request, params
            end

            it 'should redirect the the admin page for the request' do
                make_request
                response.should redirect_to(:controller => 'admin_request',
                                            :action => 'show',
                                            :id => @info_request.id)
            end

            it 'should set the request prominence to "requester_only"' do
                @info_request.should_receive(:prominence=).with('requester_only')
                @info_request.should_receive(:save!)
                make_request
            end

            it 'should not send a notification email' do
                ContactMailer.should_not_receive(:from_admin_message)
                make_request
            end

            it 'should add a notice to the flash saying that the request has been hidden' do
                make_request
                request.flash[:notice].should == "This external request has been hidden"
            end

            it 'should expire the file cache for the request' do
                @controller.should_receive(:expire_for_request)
                make_request
            end
        end

    end

end
