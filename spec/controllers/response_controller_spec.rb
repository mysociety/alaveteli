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

describe ResponseController, "when sending a followup message" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should require login" do
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
  end

  it "should not let you if you are logged in as the wrong user" do
    session[:user_id] = users(:silly_name_user).id
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    expect(response).to render_template('user/wrong_user')
  end

  it "should give an error and render 'show_response' template when a body isn't given" do
    session[:user_id] = users(:bob_smith_user).id
    post :show_response, :outgoing_message => { :body => "", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1

    # TODO: how do I check the error message here?
    expect(response).to render_template('show_response')
  end

  it "should show preview when input is good" do
    session[:user_id] = users(:bob_smith_user).id
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1, :preview => 1
    expect(response).to render_template('followup_preview')
  end

  it "should allow re-editing of a preview" do
    session[:user_id] = users(:bob_smith_user).id
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1, :preview => 0, :reedit => "Re-edit this request"
    expect(response).to render_template('show_response')
  end

  it "should send the follow up message if you are the right user" do
    # fake that this is a clarification
    info_requests(:fancy_dog_request).set_described_state('waiting_clarification')
    expect(info_requests(:fancy_dog_request).described_state).to eq('waiting_clarification')
    expect(info_requests(:fancy_dog_request).get_last_public_response_event.calculated_state).to eq('waiting_clarification')

    # make the followup
    session[:user_id] = users(:bob_smith_user).id

    post :show_response,
    :outgoing_message => {
      :body => "What a useless response! You suck.",
      :what_doing => 'normal_sort'
    },
      :id => info_requests(:fancy_dog_request).id,
      :incoming_message_id => incoming_messages(:useless_incoming_message),
      :submitted_followup => 1

    # check it worked
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/What a useless response! You suck./)
    expect(mail.to_addrs.first.to_s).to eq("foiperson@localhost")

    expect(response).
      to redirect_to(show_request_url(info_requests(:fancy_dog_request).url_title))

    # and that the status changed
    info_requests(:fancy_dog_request).reload
    expect(info_requests(:fancy_dog_request).described_state).to eq('waiting_response')
    expect(info_requests(:fancy_dog_request).get_last_public_response_event.calculated_state).to eq('waiting_clarification')
  end

  it "should give an error if the same followup is submitted twice" do
    session[:user_id] = users(:bob_smith_user).id

    # make the followup once
    post :show_response, :outgoing_message => { :body => "Stop repeating yourself!", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    expect(response).
      to redirect_to(show_request_url(info_requests(:fancy_dog_request).url_title))

    # second time should give an error
    post :show_response, :outgoing_message => { :body => "Stop repeating yourself!", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    # TODO: how do I check the error message here?
    expect(response).to render_template('show_response')
  end

end
