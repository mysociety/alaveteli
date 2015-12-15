# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResponseController do
  render_views

  let(:request_user) { FactoryGirl.create(:user) }
  let(:request) { FactoryGirl.create(:info_request_with_incoming, :user => request_user) }
  let(:message_id) { request.incoming_messages[0].id }

  describe "GET new_followup" do

    it "displays 'wrong user' message when not logged in as the request owner" do
      session[:user_id] = FactoryGirl.create(:user)
      get :new_followup, :id => request.id,
                         :incoming_message_id => message_id
      expect(response).to render_template('user/wrong_user')
    end

    it "does not allow follow ups to external requests" do
      session[:user_id] = FactoryGirl.create(:user)
      external_request = FactoryGirl.create(:external_request)
      incoming = FactoryGirl.create(:incoming_message,
                                    :info_request => external_request)
      external_request.log_event("response", {:incoming_message_id => incoming.id})
      get :new_followup, :id => external_request.id,
                         :incoming_message_id => incoming.id
      expect(response).to render_template('response/followup_bad')
      expect(assigns[:reason]).to eq('external')
    end

    it "redirects to the signin page if not logged in" do
      get :new_followup, :id => request.id, :incoming_message_id => message_id
      expect(response).
        to redirect_to(signin_url(:token => get_last_post_redirect.token))
    end

    it "calls the message a followup if there is an incoming message" do
      expected_reason = "To send a follow up message to #{request.public_body.name}"
      get :new_followup, :id => request.id, :incoming_message_id => message_id
       expect(get_last_post_redirect.reason_params[:web]).to eq(expected_reason)
    end

    it "calls the message a reply if there is no incoming message" do
      expected_reason = "To reply to #{request.public_body.name}."
      get :new_followup, :id => request.id
      expect(get_last_post_redirect.reason_params[:web]).to eq(expected_reason)
    end

    context "logged in as the request owner" do

      before(:each) do
        session[:user_id] = request_user.id
      end

      it "shows the followup form" do
        get :new_followup, :id => request.id, :incoming_message_id => message_id
        expect(response).to render_template('new_followup')
      end

      it "offers the opportunity to reply to the main address" do
        get :new_followup, :id => request.id, :incoming_message_id => message_id
        expect(response.body).
          to have_css("div#other_recipients ul li", :text => "the main FOI contact address for")
      end

      it "offers an opportunity to reply to another address" do
        open_request = FactoryGirl.create(:info_request_with_incoming,
                                          :user => request_user,
                                          :allow_new_responses_from => "anybody")
        receive_incoming_mail('incoming-request-plain.email',
                              open_request.incoming_email, "Frob <frob@bonce.com>")
        get :new_followup, :id => open_request.id,
                           :incoming_message_id => open_request.incoming_messages[0].id
        expect(response.body).to have_css("div#other_recipients ul li", :text => "Frob")
      end

      context "the request is hidden" do

        let(:hidden_request) do
          FactoryGirl.create(:info_request_with_incoming, :user => request_user,
                                                          :prominence => "hidden")
        end

        let(:hidden_message) do
          FactoryGirl.create(:incoming_message, :info_request => hidden_request)
        end

        before do
          hidden_request.
            log_event("response", {:incoming_message_id => hidden_message.id})
        end

        it "does not show the form, even to the request owner" do
          get :new_followup, :id => hidden_request.id,
                             :incoming_message_id => hidden_message.id
          expect(response).to render_template('request/hidden')
        end

        it 'responds to a json request with a 403' do
          get :new_followup, :id => hidden_request.id,
                             :incoming_message_id => hidden_message.id,
                             :format => 'json'
          expect(response.code).to eq('403')
        end

      end

    end

  end

  describe "POST create_followup" do

    let(:dummy_message) do
      { :body => "What a useless response! You suck.",
        :what_doing => 'normal_sort' }
    end

    it "redirects to the signin page if not logged in" do
      post :create_followup, :outgoing_message => dummy_message,
                             :id => request.id,
                             :incoming_message_id => message_id
      expect(response).
        to redirect_to(signin_url(:token => get_last_post_redirect.token))
    end

    it "displays a wrong user message when not logged in as the request owner" do
      session[:user_id] = FactoryGirl.create(:user)
      post :create_followup, :outgoing_message => dummy_message,
                             :id => request.id,
                             :incoming_message_id => message_id
      expect(response).to render_template('user/wrong_user')
    end

    context "logged in as the request owner" do

      before(:each) do
        session[:user_id] = request_user.id
      end

      it "shows a preview when input is good" do
        post :create_followup, :outgoing_message => dummy_message,
                               :id => request.id,
                               :incoming_message_id => message_id,
                               :preview => 1
        expect(response).to render_template('followup_preview')
      end

      it "displays the followup form with an error when the message body is blank" do
        post :create_followup, :id => request.id,
                               :outgoing_message => {
                                  :body => "",
                                  :what_doing => "normal_sort" },
                               :incoming_message_id => message_id

        expect(response).to render_template("new_followup")
        expect(response.body).to include("Please enter your follow up message")
      end

      it "allows re-editing of a preview" do
        post :create_followup, :outgoing_message => dummy_message,
                               :id => request.id,
                               :incoming_message_id => message_id,
                               :reedit => "Re-edit this request"
        expect(response).to render_template('new_followup')
      end

      context "when not sent preview or reedit params" do

        it "sends the follow up message" do
          post :create_followup, :outgoing_message => dummy_message,
                                 :id => request.id,
                                 :incoming_message_id => message_id

          # check it worked
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.size).to eq(1)
          mail = deliveries[0]
          expect(mail.body).to match(/What a useless response! You suck./)
          expect(mail.to_addrs.first.to_s).to eq(request.public_body.request_email)
        end

        it "redirects to the request page" do
          post :create_followup, :outgoing_message => dummy_message,
                                 :id => request.id,
                                 :incoming_message_id => message_id

          expect(response).
            to redirect_to(show_request_url(:url_title => request.url_title))
        end

        it "displays a confirmation once the message has been sent" do
          post :create_followup, :outgoing_message => dummy_message,
                                 :id => request.id,
                                 :incoming_message_id => message_id
          expect(flash[:notice]).to eq('Your follow up message has been sent on its way.')
        end

        it "displays an error if the request has been closed to new responses" do
          closed_request = FactoryGirl.create(:info_request_with_incoming,
                                              :user => request_user,
                                              :allow_new_responses_from => "nobody")

          post :create_followup, :outgoing_message => dummy_message,
                                 :id => closed_request.id,
                                 :incoming_message_id => closed_request.incoming_messages[0].id

          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.size).to eq(0)

          expect(response).to render_template('new_followup')
          expect(response.body).
            to include('Your follow up has not been sent because this request has been stopped to prevent spam.')
        end

      end

      context "the same followup is submitted twice" do

        before(:each) do
          post :create_followup, :outgoing_message => dummy_message,
                                 :id => request.id,
                                 :incoming_message_id => message_id

          post :create_followup, :outgoing_message => dummy_message,
                                 :id => request.id,
                                 :incoming_message_id => message_id
        end

        it "displays the form with an error message" do
          expect(response).to render_template('new_followup')
          expect(response.body).
            to include('You previously submitted that exact follow up message for this request.')
        end

        it "only delivers the message once" do
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.size).to eq(1)
        end

      end

      it "sends the follow up message if you are the right user" do
        post :create_followup, :outgoing_message => dummy_message,
                               :id => request.id,
                               :incoming_message_id => message_id,
                               :submitted_followup => 1

        # check it worked
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.body).to match(/What a useless response! You suck./)
        expect(mail.to_addrs.first.to_s).to eq(request.public_body.request_email)

        expect(response).
          to redirect_to(show_request_url(request.url_title))

        # and that the status changed
        request.reload
        expect(request.described_state).to eq('waiting_response')
      end

    end

  end

end

