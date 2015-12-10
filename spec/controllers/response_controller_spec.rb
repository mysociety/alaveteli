# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResponseController, "when viewing an individual response for reply/followup" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should ask for login if you are logged in as wrong person" do
    session[:user_id] = users(:silly_name_user).id
    get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response).to render_template('user/wrong_user')
  end

  it "should show the response if you are logged in as right person" do
    session[:user_id] = users(:bob_smith_user).id
    get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response).to render_template('show_response')
  end

  it "should offer the opportunity to reply to the main address" do
    session[:user_id] = users(:bob_smith_user).id
    get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response.body).to have_css("div#other_recipients ul li", :text => "the main FOI contact address for")
  end

  it "should offer an opportunity to reply to another address" do
    session[:user_id] = users(:bob_smith_user).id
    ir = info_requests(:fancy_dog_request)
    ir.allow_new_responses_from = "anybody"
    ir.save!
    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "Frob <frob@bonce.com>")
    get :show_response, :id => ir.id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response.body).to have_css("div#other_recipients ul li", :text => "Frob")
  end

  context 'when a request is hidden' do

    before do
      ir = info_requests(:fancy_dog_request)
      ir.prominence = 'hidden'
      ir.save!

      session[:user_id] = users(:bob_smith_user).id
    end

    it "should not show individual responses, even if request owner" do
      get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
      expect(response).to render_template('request/hidden')
    end

    it 'should respond to a json request for a hidden request with a 403 code and no body' do
      get :show_response, :id => info_requests(:fancy_dog_request).id,
        :incoming_message_id => incoming_messages(:useless_incoming_message),
        :format => 'json'

      expect(response.code).to eq('403')
    end

  end

  describe 'when viewing a response for an external request' do

    it 'should show a message saying that external requests cannot be followed up' do
      get :show_response, :id => info_requests(:external_request).id
      expect(response).to render_template('followup_bad')
      expect(assigns[:reason]).to eq('external')
    end

    it 'should be successful' do
      get :show_response, :id => info_requests(:external_request).id
      expect(response).to be_success
    end

  end

end
