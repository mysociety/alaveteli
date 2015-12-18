# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResponseController do
  render_views

  let(:request_user) { FactoryGirl.create(:user) }
  let(:request) { FactoryGirl.create(:info_request_with_incoming, :user => request_user) }
  let(:message_id) { request.incoming_messages[0].id }

  describe "GET show_response" do

    it "displays 'wrong user' message when not logged in as the request owner" do
      session[:user_id] = FactoryGirl.create(:user)
      get :show_response, :id => request.id,
                         :incoming_message_id => message_id
      expect(response).to render_template('user/wrong_user')
    end

    it "redirects to the signin page if not logged in" do
      get :show_response, :id => request.id
      expect(response).
        to redirect_to(signin_url(:token => get_last_post_redirect.token))
    end

    it "calls the message a followup if there is an incoming message" do
      expected_reason = "To send a follow up message to #{request.public_body.name}"
      get :show_response, :id => request.id, :incoming_message_id => message_id
       expect(get_last_post_redirect.reason_params[:web]).to eq(expected_reason)
    end

    it "calls the message a reply if there is no incoming message" do
      expected_reason = "To reply to #{request.public_body.name}."
      get :show_response, :id => request.id
      expect(get_last_post_redirect.reason_params[:web]).to eq(expected_reason)
    end

    context "logged in as the request owner" do
      before(:each) do
        session[:user_id] = request_user.id
      end

      it "shows the followup form" do
        get :show_response, :id => request.id, :incoming_message_id => message_id
        expect(response).to render_template('show_response')
      end

      it "offers the opportunity to reply to the main address" do
        get :show_response, :id => request.id, :incoming_message_id => message_id
        expect(response.body).
          to have_css("div#other_recipients ul li", :text => "the main FOI contact address for")
      end

      it "offers an opportunity to reply to another address" do
        open_request = FactoryGirl.create(:info_request_with_incoming,
                                          :user => request_user,
                                          :allow_new_responses_from => "anybody")
        receive_incoming_mail('incoming-request-plain.email',
                              open_request.incoming_email, "Frob <frob@bonce.com>")
        get :show_response, :id => open_request.id,
                           :incoming_message_id => open_request.incoming_messages[0].id
        expect(response.body).to have_css("div#other_recipients ul li", :text => "Frob")
      end

      context "the request is hidden" do
        let(:hidden_request) do
          FactoryGirl.create(:info_request_with_incoming, :user => request_user,
                                                          :prominence => "hidden")
        end

        it "does not show the form, even to the request owner" do
          get :show_response, :id => hidden_request.id
          expect(response).to render_template('request/hidden')
        end

        it 'responds to a json request with a 403' do
          incoming_message_id = hidden_request.incoming_messages[0].id
          get :show_response, :id => hidden_request.id,
                              :incoming_message_id => incoming_message_id,
                              :format => 'json'
          expect(response.code).to eq('403')
        end

      end

    end

    context 'when viewing a response for an external request' do

      it "does not allow follow ups to external requests" do
        session[:user_id] = FactoryGirl.create(:user)
        external_request = FactoryGirl.create(:external_request)
        get :show_response, :id => external_request.id
        expect(response).to render_template('followup_bad')
        expect(assigns[:reason]).to eq('external')
      end

      it 'the response code should be successful' do
        session[:user_id] = FactoryGirl.create(:user)
        get :show_response, :id => FactoryGirl.create(:external_request).id
        expect(response).to be_success
      end

    end

  end

end
