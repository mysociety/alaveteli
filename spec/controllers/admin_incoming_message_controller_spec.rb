# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminIncomingMessageController, "when administering incoming messages" do

    describe 'when destroying an incoming message' do

        before(:each) do
            basic_auth_login @request
            load_raw_emails_data
        end

        before do
            @im = incoming_messages(:useless_incoming_message)
            @controller.stub!(:expire_for_request)
        end

        it "destroys the raw email file" do
            raw_email = @im.raw_email.filepath
            assert_equal File.exists?(raw_email), true
            post :destroy, :id => @im.id
            assert_equal File.exists?(raw_email), false
        end

        it 'asks the incoming message to fully destroy itself' do
            IncomingMessage.stub!(:find).and_return(@im)
            @im.should_receive(:fully_destroy)
            post :destroy, :id => @im.id
        end

        it 'expires the file cache for the associated info_request' do
            @controller.should_receive(:expire_for_request).with(@im.info_request)
            post :destroy, :id => @im.id
        end

    end

    describe 'when redelivering an incoming message' do

        before(:each) do
            basic_auth_login @request
            load_raw_emails_data
        end

        it 'expires the file cache for the previous request' do
            current_info_request = info_requests(:fancy_dog_request)
            destination_info_request = info_requests(:naughty_chicken_request)
            incoming_message = incoming_messages(:useless_incoming_message)
            @controller.should_receive(:expire_for_request).with(current_info_request)
            post :redeliver, :id => incoming_message.id,
                             :url_title => destination_info_request.url_title
        end

        it 'should succeed, even if a duplicate xapian indexing job is created' do

            with_duplicate_xapian_job_creation do
                current_info_request = info_requests(:fancy_dog_request)
                destination_info_request = info_requests(:naughty_chicken_request)
                incoming_message = incoming_messages(:useless_incoming_message)
                post :redeliver, :id => incoming_message.id,
                                 :url_title => destination_info_request.url_title
            end

        end

    end

    describe 'when editing an incoming message' do

        before do
            @incoming = FactoryGirl.create(:incoming_message)
        end

        it 'should be successful' do
            get :edit, :id => @incoming.id
            response.should be_success
        end

        it 'should assign the incoming message to the view' do
            get :edit, :id => @incoming.id
            assigns[:incoming_message].should == @incoming
        end

    end

    describe 'when updating an incoming message' do

        before do
            @incoming = FactoryGirl.create(:incoming_message, :prominence => 'normal')
            @default_params = {:id => @incoming.id,
                               :incoming_message => {:prominence => 'hidden',
                                                     :prominence_reason => 'dull'} }
        end

        def make_request(params=@default_params)
            post :update, params
        end

        it 'should save the prominence of the message' do
            make_request
            @incoming.reload
            @incoming.prominence.should == 'hidden'
        end

        it 'should save a prominence reason for the message' do
            make_request
            @incoming.reload
            @incoming.prominence_reason.should == 'dull'
        end

        it 'should log an "edit_incoming" event on the info_request' do
            @controller.stub!(:admin_current_user).and_return("Admin user")
            make_request
            @incoming.reload
            last_event = @incoming.info_request_events.last
            last_event.event_type.should == 'edit_incoming'
            last_event.params.should == { :incoming_message_id => @incoming.id,
                                          :editor => "Admin user",
                                          :old_prominence => "normal",
                                          :prominence => "hidden",
                                          :old_prominence_reason => nil,
                                          :prominence_reason => "dull" }
        end

        it 'should expire the file cache for the info request' do
            @controller.should_receive(:expire_for_request).with(@incoming.info_request)
            make_request
        end

        context 'if the incoming message saves correctly' do

            it 'should redirect to the admin info request view' do
                make_request
                response.should redirect_to admin_request_url(@incoming.info_request)
            end

            it 'should show a message that the incoming message has been updated' do
                make_request
                flash[:notice].should == 'Incoming message successfully updated.'
            end

        end

        context 'if the incoming message is not valid' do

            it 'should render the edit template' do
                make_request({:id => @incoming.id,
                              :incoming_message => {:prominence => 'fantastic',
                                                    :prominence_reason => 'dull'}})
                response.should render_template("edit")
            end

        end
    end

end
