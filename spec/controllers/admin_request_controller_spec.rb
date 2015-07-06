# -*- encoding : utf-8 -*-
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

    describe 'when fully destroying a request' do

        it 'expires the file cache for that request' do
            info_request = info_requests(:badger_request)
            @controller.should_receive(:expire_for_request).with(info_request)
            get :destroy, { :id => info_request }
        end

        it 'uses a different flash message to avoid trying to fetch a non existent user record' do
            info_request = info_requests(:external_request)
            post :destroy, { :id => info_request.id }
            request.flash[:notice].should include('external')
        end

    end

end

describe AdminRequestController, "when administering the holding pen" do
    render_views
    before(:each) do
        basic_auth_login @request
        load_raw_emails_data
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
            post :hide, :id => ir.id, :explanation => "Foo", :reason => "vexatious"
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
            post :hide, :id => ir.id, :explanation => "Foo", :reason => "vexatious"
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
                post :hide, params
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
