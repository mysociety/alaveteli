require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminIncomingMessageController, "when administering incoming messages" do

    before(:each) do
        basic_auth_login @request
        load_raw_emails_data
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

    describe 'when redelivering an incoming message' do

        it 'expires the file cache for the previous request' do
            current_info_request = info_requests(:fancy_dog_request)
            destination_info_request = info_requests(:naughty_chicken_request)
            incoming_message = incoming_messages(:useless_incoming_message)
            @controller.should_receive(:expire_for_request).with(current_info_request)
            post :redeliver_incoming, :redeliver_incoming_message_id => incoming_message.id,
                                      :url_title => destination_info_request.url_title
        end


    end

end
