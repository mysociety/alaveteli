# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When administering the site" do

  before do
    AlaveteliConfiguration.stub!(:skip_admin_auth).and_return(false)
    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it "allows an admin to log in as another user" do
    # post to the "log in as" url to log in as Bob
    @admin.post_via_redirect "/en/admin/users/#{users(:bob_smith_user).id}/login_as"
    @admin.response.should be_success
    @admin.session[:user_id].should == users(:bob_smith_user).id
  end

  it 'does not allow a non-admin user to login as another user' do
    robin = login(:robin_user)
    robin.post_via_redirect "/en/admin/users/#{users(:bob_smith_user).id}/login_as"
    robin.response.should be_success
    robin.session[:user_id].should_not == users(:bob_smith_user).id
  end

  it "allows redelivery of an incoming message to a closed request" do
    ir = info_requests(:fancy_dog_request)
    close_request(ir)
    InfoRequest.holding_pen_request.incoming_messages.length.should == 0
    ir.incoming_messages.length.should == 1
    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
    InfoRequest.holding_pen_request.incoming_messages.length.should == 1
    new_im = InfoRequest.holding_pen_request.incoming_messages[0]
    ir.incoming_messages.length.should == 1
    post_params = { 'url_title' => ir.url_title }
    @admin.post "/en/admin/incoming_messages/#{new_im.id}/redeliver", post_params
    @admin.response.location.should == 'http://www.example.com/en/admin/requests/101'
    ir = InfoRequest.find_by_url_title(ir.url_title)
    ir.incoming_messages.length.should == 2

    InfoRequest.holding_pen_request.incoming_messages.length.should == 0
  end

  it "allows redelivery of an incoming message to more than one request" do

    ir1 = info_requests(:fancy_dog_request)
    close_request(ir1)
    ir1.incoming_messages.length.should == 1
    ir2 = info_requests(:another_boring_request)
    ir2.incoming_messages.length.should == 1

    receive_incoming_mail('incoming-request-plain.email', ir1.incoming_email, "frob@nowhere.com")
    InfoRequest.holding_pen_request.incoming_messages.length.should == 1

    new_im = InfoRequest.holding_pen_request.incoming_messages[0]
    post_params = { 'url_title' => "#{ir1.url_title},#{ir2.url_title}" }
    @admin.post "/en/admin/incoming_messages/#{new_im.id}/redeliver", post_params
    ir1.reload
    ir1.incoming_messages.length.should == 2
    ir2.reload
    ir2.incoming_messages.length.should == 2
    @admin.response.location.should == 'http://www.example.com/en/admin/requests/106'
    InfoRequest.holding_pen_request.incoming_messages.length.should == 0
  end

  describe 'when administering the holding pen' do

    it "shows a rejection reason for an incoming message from an invalid address" do
      ir = FactoryGirl.create(:info_request, :allow_new_responses_from => 'authority_only',
                              :handle_rejected_responses => 'holding_pen')
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
      raw_email = InfoRequest.holding_pen_request.get_last_public_response.raw_email
      @admin.get "/en/admin/raw_emails/#{raw_email.id}"
      @admin.response.should contain "Only the authority can reply to this request"
    end

    it "guesses a misdirected request" do
      ir = FactoryGirl.create(:info_request, :allow_new_responses_from => 'authority_only',
                              :handle_rejected_responses => 'holding_pen')
      mail_to = "request-#{ir.id}-asdfg@example.com"
      receive_incoming_mail('incoming-request-plain.email', mail_to)
      interesting_email = InfoRequest.holding_pen_request.get_last_public_response.raw_email
      # now we add another message to the queue, which we're not interested in
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
      InfoRequest.holding_pen_request.incoming_messages.length.should == 2
      @admin.get "/en/admin/raw_emails/#{interesting_email.id}"
      @admin.response.should contain "Could not identify the request"
      @admin.response.should contain ir.title
    end


  end
end
