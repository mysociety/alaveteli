# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When administering the site" do

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)
    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it "allows an admin to log in as another user" do
    # post to the "log in as" url to log in as Bob
    @admin.post_via_redirect "/en/admin/users/#{users(:bob_smith_user).id}/login_as"
    expect(@admin.response).to be_success
    expect(@admin.session[:user_id]).to eq(users(:bob_smith_user).id)
  end

  it 'does not allow a non-admin user to login as another user' do
    robin = login(:robin_user)
    robin.post_via_redirect "/en/admin/users/#{users(:bob_smith_user).id}/login_as"
    expect(robin.response).to be_success
    expect(robin.session[:user_id]).not_to eq(users(:bob_smith_user).id)
  end

  it "allows redelivery of an incoming message to a closed request" do
    ir = info_requests(:fancy_dog_request)
    close_request(ir)
    expect(InfoRequest.holding_pen_request.incoming_messages.length).to eq(0)
    expect(ir.incoming_messages.length).to eq(1)
    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
    expect(InfoRequest.holding_pen_request.incoming_messages.length).to eq(1)
    new_im = InfoRequest.holding_pen_request.incoming_messages[0]
    expect(ir.incoming_messages.length).to eq(1)
    post_params = { 'url_title' => ir.url_title }
    @admin.post "/en/admin/incoming_messages/#{new_im.id}/redeliver", post_params
    expect(@admin.response.location).to eq('http://www.example.com/en/admin/requests/101')
    ir = InfoRequest.find_by_url_title(ir.url_title)
    expect(ir.incoming_messages.length).to eq(2)

    expect(InfoRequest.holding_pen_request.incoming_messages.length).to eq(0)
  end

  it "allows redelivery of an incoming message to more than one request" do

    ir1 = info_requests(:fancy_dog_request)
    close_request(ir1)
    expect(ir1.incoming_messages.length).to eq(1)
    ir2 = info_requests(:another_boring_request)
    expect(ir2.incoming_messages.length).to eq(1)

    receive_incoming_mail('incoming-request-plain.email', ir1.incoming_email, "frob@nowhere.com")
    expect(InfoRequest.holding_pen_request.incoming_messages.length).to eq(1)

    new_im = InfoRequest.holding_pen_request.incoming_messages[0]
    post_params = { 'url_title' => "#{ir1.url_title},#{ir2.url_title}" }
    @admin.post "/en/admin/incoming_messages/#{new_im.id}/redeliver", post_params
    ir1.reload
    expect(ir1.incoming_messages.length).to eq(2)
    ir2.reload
    expect(ir2.incoming_messages.length).to eq(2)
    expect(@admin.response.location).to eq('http://www.example.com/en/admin/requests/106')
    expect(InfoRequest.holding_pen_request.incoming_messages.length).to eq(0)
  end

  describe 'when administering the holding pen' do

    it "shows a rejection reason for an incoming message from an invalid address" do
      ir = FactoryGirl.create(:info_request, :allow_new_responses_from => 'authority_only',
                              :handle_rejected_responses => 'holding_pen')
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
      raw_email = InfoRequest.holding_pen_request.get_last_public_response.raw_email
      @admin.get "/en/admin/raw_emails/#{raw_email.id}"
      expect(@admin.response).to contain "Only the authority can reply to this request"
    end

    it "guesses a misdirected request" do
      ir = FactoryGirl.create(:info_request, :allow_new_responses_from => 'authority_only',
                              :handle_rejected_responses => 'holding_pen')
      mail_to = "request-#{ir.id}-asdfg@example.com"
      receive_incoming_mail('incoming-request-plain.email', mail_to)
      interesting_email = InfoRequest.holding_pen_request.get_last_public_response.raw_email
      # now we add another message to the queue, which we're not interested in
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
      expect(InfoRequest.holding_pen_request.incoming_messages.length).to eq(2)
      @admin.get "/en/admin/raw_emails/#{interesting_email.id}"
      expect(@admin.response).to contain "Could not identify the request"
      expect(@admin.response).to contain ir.title
    end


  end
end
