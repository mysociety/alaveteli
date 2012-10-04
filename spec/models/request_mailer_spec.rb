require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestMailer, " when receiving incoming mail" do
    before(:each) do
        load_raw_emails_data
        ActionMailer::Base.deliveries = []
    end

    it "should append it to the appropriate request" do
        ir = info_requests(:fancy_dog_request)
        ir.incoming_messages.size.should == 1 # in the fixture
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 2 # one more arrives
        ir.info_request_events[-1].incoming_message_id.should_not be_nil

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ 'bob@localhost' ] # to the user who sent fancy_dog_request
        deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the email is not to any information request" do
        ir = info_requests(:fancy_dog_request)
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail('incoming-request-plain.email', 'dummy@localhost')
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1
        last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.get_last_event
        last_event.params[:rejected_reason].should == "Could not identify the request from the email address"

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ Configuration::contact_email ]
        deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the from email is empty and only authorites can reply" do
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'authority_only'
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1
        last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.get_last_event
        last_event.params[:rejected_reason].should =~ /there is no "From" address/

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ Configuration::contact_email ]
        deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the from email is unknown and only authorites can reply" do
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'authority_only'
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1
        last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.get_last_event
        last_event.params[:rejected_reason].should =~ /Only the authority can reply/

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ Configuration::contact_email ]
        deliveries.clear
    end

    it "should return incoming mail to sender when a request is stopped fully for spam" do
        # mark request as anti-spam
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'nobody'
        ir.handle_rejected_responses = 'bounce'
        ir.save!

        # test what happens if something arrives
        ir.incoming_messages.size.should == 1 # in the fixture
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 1 # nothing should arrive

        # should be a message back to sender
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ 'geraldinequango@localhost' ]
        # check attached bounce is good copy of incoming-request-plain.email
        mail.multipart?.should == true
        mail.parts.size.should == 2
        message_part = mail.parts[0].to_s
        bounced_mail = TMail::Mail.parse(mail.parts[1].body)
        bounced_mail.to.should == [ ir.incoming_email ]
        bounced_mail.from.should == [ 'geraldinequango@localhost' ]
        bounced_mail.body.include?("That's so totally a rubbish question").should be_true
        message_part.include?("marked to no longer receive responses").should be_true
        deliveries.clear
    end

    it "should return incoming mail to sender if not authority when a request is stopped for non-authority spam" do
        # mark request as anti-spam
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'authority_only'
        ir.handle_rejected_responses = 'bounce'
        ir.save!

        # Test what happens if something arrives from authority domain (@localhost)
        ir.incoming_messages.size.should == 1 # in the fixture
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "Geraldine <geraldinequango@localhost>")
        ir.incoming_messages.size.should == 2 # one more arrives

        # ... should get "responses arrived" message for original requester
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ 'bob@localhost' ] # to the user who sent fancy_dog_request
        deliveries.clear

        # Test what happens if something arrives from another domain
        ir.incoming_messages.size.should == 2 # in fixture and above
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "dummy-address@dummy.localhost")
        ir.incoming_messages.size.should == 2 # nothing should arrive

        # ... should be a bounce message back to sender
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ 'dummy-address@dummy.localhost' ]
        deliveries.clear
    end

    it "should send all new responses to holding pen if a request is marked to do so" do
        # mark request as anti-spam
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'nobody'
        ir.handle_rejected_responses = 'holding_pen'
        ir.save!

        # test what happens if something arrives
        ir = info_requests(:fancy_dog_request)
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1 # arrives in holding pen
        last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.get_last_event
        last_event.params[:rejected_reason].should =~ /allow new responses from nobody/

        # should be a message to admin regarding holding pen
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ Configuration::contact_email ]
        deliveries.clear
    end

    it "should destroy the messages sent to a request if marked to do so" do
        ActionMailer::Base.deliveries.clear
        # mark request as anti-spam
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = 'nobody'
        ir.handle_rejected_responses = 'blackhole'
        ir.save!

        # test what happens if something arrives - should be nothing
        ir = info_requests(:fancy_dog_request)
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0

        # should be no messages to anyone
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end


    it "should not mutilate long URLs when trying to word wrap them" do
        long_url = 'http://www.this.is.quite.a.long.url.flourish.org/there.is.no.way.it.is.short.whatsoever'
        body = "This is a message with quite a long URL in it. It also has a paragraph, being this one that has quite a lot of text in it to. Enough to test the wrapping of itself.

#{long_url}

And a paragraph afterwards."
        wrapped = MySociety::Format.wrap_email_body_by_paragraphs(body)
        wrapped.should include(long_url)
    end
end


describe RequestMailer, "when sending reminders to requesters to classify a response to their request" do

    before do
        Time.stub!(:now).and_return(Time.utc(2007, 11, 12, 23, 59))
        @mock_event = mock_model(InfoRequestEvent)
        @mock_response = mock_model(IncomingMessage)
        @mock_user = mock_model(User)
        @mock_request = mock_model(InfoRequest, :get_last_response_event_id => @mock_event.id,
                                                :get_last_response => @mock_response,
                                                :user_id => 2,
                                                :url_title => 'test_title',
                                                :user => @mock_user)
        InfoRequest.stub!(:find).and_return([@mock_request])
        RequestMailer.stub!(:deliver_new_response_reminder_alert)
        @sent_alert = mock_model(UserInfoRequestSentAlert, :user= =>nil,
                                                           :info_request= => nil,
                                                           :alert_type= => nil,
                                                           :info_request_event_id= => nil,
                                                           :save! => true)
        UserInfoRequestSentAlert.stub!(:new).and_return(@sent_alert)
    end

    def send_alerts
        RequestMailer.alert_new_response_reminders_internal(7, 'new_response_reminder_1')
    end

    it 'should ask for all requests that are awaiting description and whose latest response is older
        than the number of days given and that are not the holding pen' do
        expected_conditions = [ "awaiting_description = ?
                                 AND (SELECT created_at
                                      FROM info_request_events
                                      WHERE info_request_events.info_request_id = info_requests.id
                                      AND info_request_events.event_type = 'response'
                                      ORDER BY created_at desc LIMIT 1) < ?
                                 AND url_title != 'holding_pen'
                                 AND user_id IS NOT NULL".split(' ').join(' '),
                                 true, Time.now() - 7.days ]

        # compare the query string ignoring any spacing differences
        InfoRequest.should_receive(:find) do |all, query_params|
            query_string = query_params[:conditions][0]
            query_params[:conditions][0] = query_string.split(' ').join(' ')
            query_params[:conditions].should == expected_conditions
            query_params[:include].should == [ :user ]
            query_params[:order].should == 'info_requests.id'
        end

        send_alerts
    end

    it 'should raise an error if a request does not have a last response event id' do
        @mock_request.stub!(:get_last_response_event_id).and_return(nil)
        expected_message = "internal error, no last response while making alert new response reminder, request id #{@mock_request.id}"
        lambda{ send_alerts }.should raise_error(expected_message)
    end

    it 'should check to see if an alert matching the attributes of the one to be sent has already been sent' do
        expected_params =  {:conditions => [ "alert_type = ? and user_id = ? and info_request_id = ? and info_request_event_id = ?",
                            'new_response_reminder_1', 2, @mock_request.id, @mock_event.id]}
        UserInfoRequestSentAlert.should_receive(:find).with(:first, expected_params)
        send_alerts
    end

    describe 'if an alert matching the attributes of the reminder to be sent has already been sent' do

        before do
            UserInfoRequestSentAlert.stub!(:find).and_return(mock_model(UserInfoRequestSentAlert))
        end

        it 'should not send the reminder' do
            RequestMailer.should_not_receive(:deliver_new_response_reminder_alert)
            send_alerts
        end

    end

    describe 'if no alert matching the attributes of the reminder to be sent has already been sent' do

        before do
            UserInfoRequestSentAlert.stub!(:find).and_return(nil)
        end

        it 'should store the information that the reminder has been sent' do
            mock_sent_alert = mock_model(UserInfoRequestSentAlert)
            UserInfoRequestSentAlert.stub!(:new).and_return(mock_sent_alert)
            mock_sent_alert.should_receive(:info_request=).with(@mock_request)
            mock_sent_alert.should_receive(:user=).with(@mock_user)
            mock_sent_alert.should_receive(:alert_type=).with('new_response_reminder_1')
            mock_sent_alert.should_receive(:info_request_event_id=).with(@mock_request.get_last_response_event_id)
            mock_sent_alert.should_receive(:save!)
            send_alerts
        end

        it 'should send the reminder' do
            RequestMailer.should_receive(:deliver_new_response_reminder_alert)
            send_alerts
        end
    end

end

describe RequestMailer, 'when sending mail when someone has updated an old unclassified request' do

    before do
        @user = mock_model(User, :name_and_email => 'test name and email')
        @public_body = mock_model(PublicBody, :name => 'Test public body')
        @info_request = mock_model(InfoRequest, :user => @user,
                                                :law_used_full => 'Freedom of Information',
                                                :title => 'Test request',
                                                :public_body => @public_body,
                                                :display_status => 'Refused.',
                                                :url_title => 'test_request')
        @mail = RequestMailer.create_old_unclassified_updated(@info_request)
    end

    it 'should have the subject "Someone has updated the status of your request"' do
        @mail.subject.should == 'Someone has updated the status of your request'
    end

    it 'should tell them what status was picked' do
        @mail.body.should match(/"refused."/)
    end

    it 'should contain the request path' do
        @mail.body.should match(/request\/test_request/)
    end

end

describe RequestMailer, 'requires_admin' do
    before(:each) do
        user = mock_model(User, :name_and_email => 'Bruce Jones',
                                :name => 'Bruce Jones')
        @info_request = mock_model(InfoRequest, :user => user,
                                                :described_state => 'error_message',
                                                :title => 'Test request',
                                                :url_title => 'test_request',
                                                :law_used_short => 'FOI',
                                                :id => 123)
    end

    it 'body should contain the full admin URL' do
        mail = RequestMailer.deliver_requires_admin(@info_request)

        mail.body.should include('http://test.host/en/admin/request/show/123')
    end

    context 'has an ADMIN_BASE_URL set' do
        before(:each) do
            Configuration::should_receive(:admin_base_url).and_return('http://our.proxy.server/admin/alaveteli/')
        end

        it 'body should contain the full admin URL' do
            mail = RequestMailer.deliver_requires_admin(@info_request)

            mail.body.should include('http://our.proxy.server/admin/alaveteli/request/show/123')
        end
    end
end
