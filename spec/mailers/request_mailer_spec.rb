# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# TODO: Combine all these separate "describe" blocks to tidy things up

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
    last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
    last_event.params[:rejected_reason].should == "Could not identify the request from the email address"

    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 1
    mail = deliveries[0]
    mail.to.should == [ AlaveteliConfiguration::contact_email ]
    deliveries.clear
  end

  it "puts messages with a malformed To: in the holding pen" do
    request = FactoryGirl.create(:info_request)
    receive_incoming_mail('incoming-request-plain.email', 'asdfg')
    expect(InfoRequest.holding_pen_request.incoming_messages).to have(1).item
  end

  it "should parse attachments from mails sent with apple mail" do
    ir = info_requests(:fancy_dog_request)
    ir.incoming_messages.size.should == 1
    InfoRequest.holding_pen_request.incoming_messages.size.should == 0
    receive_incoming_mail('apple-mail-with-attachments.email', 'dummy@localhost')
    ir.incoming_messages.size.should == 1
    InfoRequest.holding_pen_request.incoming_messages.size.should == 1
    last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
    last_event.params[:rejected_reason].should == "Could not identify the request from the email address"

    im = IncomingMessage.last
    # Check that the attachments haven't been somehow loaded from a
    # previous test run
    im.foi_attachments.size.should == 0

    # Trace where attachments first get loaded:
    # TODO: Ideally this should be 3, but some html parts from Apple Mail
    # are being treated like attachments
    im.extract_attachments!
    im.foi_attachments.size.should == 6

    # Clean up
    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 1
    mail = deliveries[0]
    mail.to.should == [ AlaveteliConfiguration::contact_email ]
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
    last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
    last_event.params[:rejected_reason].should =~ /there is no "From" address/

    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 1
    mail = deliveries[0]
    mail.to.should == [ AlaveteliConfiguration::contact_email ]
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
    last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
    last_event.params[:rejected_reason].should =~ /Only the authority can reply/

    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 1
    mail = deliveries[0]
    mail.to.should == [ AlaveteliConfiguration::contact_email ]
    deliveries.clear
  end

  it "should ignore mail sent to known spam addresses" do
    @spam_address = FactoryGirl.create(:spam_address)

    receive_incoming_mail('incoming-request-plain.email', @spam_address.email)

    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 0
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
    bounced_mail = MailHandler.mail_from_raw_email(mail.parts[1].body.to_s)
    bounced_mail.to.should == [ ir.incoming_email ]
    bounced_mail.from.should == [ 'geraldinequango@localhost' ]
    bounced_mail.body.include?("That's so totally a rubbish question").should be_true
    message_part.include?("marked to no longer receive responses").should be_true
    deliveries.clear
  end

  it "redirects spam to the holding_pen" do
    info_request = FactoryGirl.create(:info_request)
    AlaveteliConfiguration.stub(:incoming_email_spam_action).and_return('holding_pen')
    AlaveteliConfiguration.stub(:incoming_email_spam_header).and_return('X-Spam-Score')
    AlaveteliConfiguration.stub(:incoming_email_spam_threshold).and_return(100)
    spam_email = <<-EOF.strip_heredoc
    From: EMAIL_FROM
    To: FOI Person <EMAIL_TO>
    Subject: BUY MY SPAM
    X-Spam-Score: 1000
    Plz buy my spam
    EOF

    receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

    expect(InfoRequest.holding_pen_request.incoming_messages).to have(1).item
  end

  it "discards mail over the configured spam threshold" do
    info_request = FactoryGirl.create(:info_request)
    AlaveteliConfiguration.stub(:incoming_email_spam_action).and_return('discard')
    AlaveteliConfiguration.stub(:incoming_email_spam_header).and_return('X-Spam-Score')
    AlaveteliConfiguration.stub(:incoming_email_spam_threshold).and_return(10)
    spam_email = <<-EOF.strip_heredoc
    From: EMAIL_FROM
    To: FOI Person <EMAIL_TO>
    Subject: BUY MY SPAM
    X-Spam-Score: 100

    Plz buy my spam
    EOF

    receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

    expect(ActionMailer::Base.deliveries).to be_empty
    ActionMailer::Base.deliveries.clear
  end

  it "delivers mail under the configured spam threshold" do
    info_request = FactoryGirl.create(:info_request)
    AlaveteliConfiguration.stub(:incoming_email_spam_action).and_return('discard')
    AlaveteliConfiguration.stub(:incoming_email_spam_header).and_return('X-Spam-Score')
    AlaveteliConfiguration.stub(:incoming_email_spam_threshold).and_return(1000)
    spam_email = <<-EOF.strip_heredoc
    From: EMAIL_FROM
    To: FOI Person <EMAIL_TO>
    Subject: BUY MY SPAM
    X-Spam-Score: 100

    Plz buy my spam
    EOF

    receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

    expect(ActionMailer::Base.deliveries).to have(1).item
    ActionMailer::Base.deliveries.clear
  end

  it "delivers mail without a spam header" do
    info_request = FactoryGirl.create(:info_request)
    AlaveteliConfiguration.stub(:incoming_email_spam_action).and_return('discard')
    AlaveteliConfiguration.stub(:incoming_email_spam_header).and_return('X-Spam-Score')
    AlaveteliConfiguration.stub(:incoming_email_spam_threshold).and_return(1000)
    spam_email = <<-EOF.strip_heredoc
    From: EMAIL_FROM
    To: FOI Person <EMAIL_TO>
    Subject: BUY MY SPAM

    Plz buy my spam
    EOF

    receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

    expect(info_request.incoming_messages).to have(1).item
    ActionMailer::Base.deliveries.clear
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

  it "discards rejected responses with a malformed From: when set to bounce" do
    ir = info_requests(:fancy_dog_request)
    ir.allow_new_responses_from = 'nobody'
    ir.handle_rejected_responses = 'bounce'
    ir.save!
    ir.incoming_messages.size.should == 1

    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
    ir.incoming_messages.size.should == 1

    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 0
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
    last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
    last_event.params[:rejected_reason].should =~ /allow new responses from nobody/

    # should be a message to admin regarding holding pen
    deliveries = ActionMailer::Base.deliveries
    deliveries.size.should == 1
    mail = deliveries[0]
    mail.to.should == [ AlaveteliConfiguration::contact_email ]
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
    @mock_response = mock_model(IncomingMessage, :user_can_view? => true)
    @mock_user = mock_model(User)
    @mock_request = mock_model(InfoRequest, :get_last_public_response_event_id => @mock_event.id,
                               :get_last_public_response => @mock_response,
                               :user_id => 2,
                               :url_title => 'test_title',
                               :user => @mock_user)
    InfoRequest.stub!(:find).and_return([@mock_request])
    mail_mock = mock("mail")
    mail_mock.stub(:deliver)
    RequestMailer.stub(:new_response_reminder_alert).and_return(mail_mock)
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
                                 AND (SELECT info_request_events.created_at
                                      FROM info_request_events, incoming_messages
                                       WHERE info_request_events.info_request_id = info_requests.id
                                       AND info_request_events.event_type = 'response'
                                       AND incoming_messages.id = info_request_events.incoming_message_id
                                       AND incoming_messages.prominence = 'normal'
                                      ORDER BY created_at desc LIMIT 1) < ?
                                 AND url_title != 'holding_pen'
                                 AND user_id IS NOT NULL".split(' ').join(' '),
                            true, Time.now - 7.days ]

    # compare the query string ignoring any spacing differences
    InfoRequest.should_receive(:find) do |all, query_params|
      query_string = query_params[:conditions][0]
      query_params[:conditions][0] = query_string.split(' ').join(' ')
      query_params[:conditions].should == expected_conditions
      query_params[:include].should == [ :user ]
      query_params[:order].should == 'info_requests.id'
    end.and_return [@mock_request]

    send_alerts
  end

  it 'should raise an error if a request does not have a last response event id' do
    @mock_request.stub!(:get_last_public_response_event_id).and_return(nil)
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
      RequestMailer.should_not_receive(:new_response_reminder_alert)
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
      mock_sent_alert.should_receive(:info_request_event_id=).with(@mock_request.get_last_public_response_event_id)
      mock_sent_alert.should_receive(:save!)
      send_alerts
    end

    it 'should send the reminder' do
      RequestMailer.should_receive(:new_response_reminder_alert)
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
    @mail = RequestMailer.old_unclassified_updated(@info_request)
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

describe RequestMailer, 'when generating a fake response for an upload' do

  before do
    @foi_officer = mock_model(User, :name_and_email => "FOI officer's name and email")
    @request_user = mock_model(User)
    @public_body = mock_model(PublicBody, :name => 'Test public body')
    @info_request = mock_model(InfoRequest, :user => @request_user,
                               :email_subject_followup => 'Re: Freedom of Information - Test request',
                               :incoming_name_and_email => 'Someone <someone@example.org>')
  end

  it 'should should generate a "fake response" email with a reasonable subject line' do
    fake_email = RequestMailer.fake_response(@info_request,
                                             @foi_officer,
                                             "The body of the email...",
                                             "blah.txt",
                                             "The content of blah.txt")
    fake_email.subject.should == "Re: Freedom of Information - Test request"
  end

end

describe RequestMailer, 'when sending a new response email' do

  before do
    @user = mock_model(User, :name_and_email => 'test name and email')
    @public_body = mock_model(PublicBody, :name => 'Test public body')
    @info_request = mock_model(InfoRequest, :user => @user,
                               :law_used_full => 'Freedom of Information',
                               :title => 'Here is a character that needs quoting …',
                               :public_body => @public_body,
                               :display_status => 'Refused.',
                               :url_title => 'test_request')
    @incoming_message = mock_model(IncomingMessage, :info_request => @info_request)
  end

  it 'should not error when sending mails requests with characters requiring quoting in the subject' do
    @mail = RequestMailer.new_response(@info_request, @incoming_message)
  end

  it 'should not create HTML entities in the subject line' do
    mail = RequestMailer.new_response(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:incoming_message))
    expect(mail.subject).to eq "New response to your FOI request - Here's a request"
  end
end

describe RequestMailer, 'requires_admin' do
  before(:each) do
    user = mock_model(User, :name_and_email => 'Bruce Jones',
                      :name => 'Bruce Jones')
    @info_request = mock_model(InfoRequest, :user => user,
                               :described_state => 'error_message',
                               :title => "It's a Test request",
                               :url_title => 'test_request',
                               :law_used_short => 'FOI',
                               :id => 123)
  end

  it 'body should contain the full admin URL' do
    mail = RequestMailer.requires_admin(@info_request).deliver
    mail.body.should include('http://test.host/en/admin/requests/123')
  end

  it "body should contain the message from the user" do
    mail = RequestMailer.requires_admin(@info_request, nil, "Something has gone wrong").deliver
    mail.body.should include 'Something has gone wrong'
  end

  it 'should not create HTML entities in the subject line' do
    expect(RequestMailer.requires_admin(@info_request).subject).to eq "FOI response requires admin (error_message) - It's a Test request"
  end
end

describe RequestMailer, "overdue_alert" do
  it 'should not create HTML entities in the subject line' do
    mail = RequestMailer.overdue_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:user))
    expect(mail.subject).to eq "Delayed response to your FOI request - Here's a request"
  end
end

describe RequestMailer, "very_overdue_alert" do
  it 'should not create HTML entities in the subject line' do
    mail = RequestMailer.very_overdue_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:user))
    expect(mail.subject).to eq "You're long overdue a response to your FOI request - Here's a request"
  end
end

describe RequestMailer, "not_clarified_alert" do
  it 'should not create HTML entities in the subject line' do
    mail = RequestMailer.not_clarified_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:incoming_message))
    expect(mail.subject).to eq "Clarify your FOI request - Here's a request"
  end
end

describe RequestMailer, "comment_on_alert" do
  it 'should not create HTML entities in the subject line' do
    mail = RequestMailer.comment_on_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:comment))
    expect(mail.subject).to eq "Somebody added a note to your FOI request - Here's a request"
  end
end

describe RequestMailer, "comment_on_alert_plural" do
  it 'should not create HTML entities in the subject line' do
    mail = RequestMailer.comment_on_alert_plural(FactoryGirl.create(:info_request, :title => "Here's a request"), 2, FactoryGirl.create(:comment))
    expect(mail.subject).to eq "Some notes have been added to your FOI request - Here's a request"
  end
end
