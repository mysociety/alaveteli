require 'spec_helper'

RSpec.describe FollowupsController do
  render_views

  let(:request_user) { FactoryBot.create(:user) }
  let(:request) do
    FactoryBot.create(:info_request_with_incoming, user: request_user)
  end
  let(:message_id) { request.incoming_messages[0].id }
  let(:pro_user) { FactoryBot.create(:pro_user) }

  describe "GET #new" do
    context "when not logged in" do
      it 'raises an ActiveRecord::RecordNotFound error for an embargoed request' do
        embargoed_request = FactoryBot.create(:embargoed_request)
        expect {
          get :new, params: { request_url_title: embargoed_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when a pro user is logged in" do
      before do
        sign_in pro_user
      end

      it 'finds their own embargoed requests' do
        embargoed_request = FactoryBot.create(:embargoed_request,
                                              user: pro_user)
        get :new, params: { request_url_title: embargoed_request.url_title }
        expect(response).to be_successful
      end

      it "displays 'wrong user' message when not logged in as the request owner" do
        get :new, params: {
          request_url_title: request.url_title,
          incoming_message_id: message_id
        }
        expect(response).to render_template('user/wrong_user')
      end

      it 'raises an ActiveRecord::RecordNotFound error for other embargoed requests' do
        embargoed_request = FactoryBot.create(:embargoed_request)
        expect {
          get :new, params: { request_url_title: embargoed_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "displays 'wrong user' message when not logged in as the request owner" do
      sign_in FactoryBot.create(:user)
      get :new, params: {
        request_url_title: request.url_title,
        incoming_message_id: message_id
      }
      expect(response).to render_template('user/wrong_user')
    end

    it "does not allow follow ups to external requests" do
      sign_in FactoryBot.create(:user)
      external_request = FactoryBot.create(:external_request)
      get :new, params: { request_url_title: external_request.url_title }
      expect(response).to render_template('followup_bad')
      expect(assigns[:reason]).to eq('external')
    end

    it "redirects to the signin page if not logged in" do
      get :new, params: { request_url_title: request.url_title }
      expect(response).
        to redirect_to(signin_url(token: get_last_post_redirect.token))
    end

    it "calls the message a followup if there is an incoming message" do
      expected_reason = "To send a follow up message " \
        "to #{request.public_body.name}"
      get :new, params: { request_url_title: request.url_title,
                          incoming_message_id: message_id }
      expect(get_last_post_redirect.reason_params[:web]).to eq(expected_reason)
    end

    it "calls the message a reply if there is no incoming message" do
      expected_reason = "To reply to #{request.public_body.name}."
      get :new, params: { request_url_title: request.url_title }
      expect(get_last_post_redirect.reason_params[:web]).to eq(expected_reason)
    end

    context "logged in as the request owner" do
      before(:each) do
        sign_in request_user
      end

      it "shows the followup form" do
        get :new, params: { request_url_title: request.url_title }
        expect(response).to render_template('new')
      end

      it "shows the followup form when replying to an incoming message" do
        get :new, params: { request_url_title: request.url_title,
                            incoming_message_id: message_id }
        expect(response).to render_template('new')
      end

      context 'the request is still embargoed but the user is no longer pro' do
        before { request.create_embargo!(embargo_duration: '3_months') }

        it 'shows the followup form' do
          get :new, params: { request_url_title: request.url_title }
          expect(response).to render_template('new')
        end
      end

      context 'the request has responses' do
        let(:message_id) { request.incoming_messages[0].id }

        before do
          allow_any_instance_of(IncomingMessage).
             to receive(:valid_to_reply_to?).and_return(true)
          receive_incoming_mail('incoming-request-plain.email',
                                email_to: request.incoming_email,
                                email_from: 'Frob <frob@bonce.com>')
        end

        it "offers the opportunity to reply to the main address" do
          get :new, params: { request_url_title: request.url_title,
                              incoming_message_id: message_id }
          expect(response.body).
            to have_css("div#other_recipients ul li",
                        text: "the main FOI contact address for")
        end

        it "offers an opportunity to reply to another address" do
          get :new, params: {
            request_url_title: request.url_title,
            incoming_message_id: message_id
          }
          expect(response.body).
            to have_css("div#other_recipients ul li", text: "Frob")
        end
      end

      context "the request is hidden" do
        let(:hidden_request) do
          FactoryBot.create(:info_request_with_incoming, user: request_user,
                                                         prominence: "hidden")
        end

        it "does not show the form, even to the request owner" do
          get :new, params: { request_url_title: hidden_request.url_title }
          expect(response).to render_template('request/hidden')
        end

        it 'responds to a json request by raising unknown format error' do
          incoming_message_id = hidden_request.incoming_messages[0].id
          expect do
            get :new, params: {
              request_url_title: hidden_request.url_title,
              incoming_message_id: incoming_message_id,
              format: 'json'
            }
          end.to raise_error ActionController::UnknownFormat
        end
      end
    end

    context 'when viewing a response for an external request' do
      it "does not allow follow ups to external requests" do
        sign_in FactoryBot.create(:user)
        external_request = FactoryBot.create(:external_request)
        get :new, params: { request_url_title: external_request.url_title }
        expect(response).to render_template('followup_bad')
        expect(assigns[:reason]).to eq('external')
      end

      it 'the response code should be successful' do
        sign_in FactoryBot.create(:user)
        get :new, params: {
          request_url_title: FactoryBot.create(:external_request).url_title
        }
        expect(response).to be_successful
      end
    end

    context 'when viewing a response for an embargoed request' do
      let(:pro_user) { FactoryBot.create(:pro_user) }
      let(:embargoed_request) do
        FactoryBot.create(:embargoed_request, user: pro_user)
      end

      it "sets @in_pro_area" do
        sign_in pro_user
        with_feature_enabled(:alaveteli_pro) do
          get :new, params: { request_url_title: embargoed_request.url_title }
          expect(assigns[:in_pro_area]).to eq true
        end
      end
    end

    context 'setting refusal advice' do
      before { sign_in request.user }

      it 'initialise without internal_review option' do
        expect(RefusalAdvice).to receive(:default).with(
          request, internal_review: false, user: request.user
        ).and_call_original

        get :new, params: { request_url_title: request.url_title }
      end

      it 'initialise with internal_review option' do
        expect(RefusalAdvice).to receive(:default).with(
          request, internal_review: true, user: request.user
        ).and_call_original

        get :new, params: {
          request_url_title: request.url_title,
          internal_review: 1
        }
      end

      it 'assigns @refusal_advice' do
        get :new, params: { request_url_title: request.url_title }
        expect(assigns[:refusal_advice]).to be_a(RefusalAdvice)
      end
    end
  end

  describe "POST #preview" do
    let(:dummy_message) do
      { body: "What a useless response! You suck.",
        what_doing: 'normal_sort' }
    end

    context "when not logged in" do
      it 'raises an ActiveRecord::RecordNotFound error for an embargoed request' do
        embargoed_request = FactoryBot.create(:embargoed_request)
        expect {
          post :preview, params: {
            outgoing_message: dummy_message,
            request_url_title: embargoed_request.url_title
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to the signin page" do
        post :preview, params: {
          outgoing_message: dummy_message,
          request_url_title: request.url_title,
          incoming_message_id: message_id
        }
        expect(response).
          to redirect_to(signin_url(token: get_last_post_redirect.token))
      end
    end

    context "when a pro user is logged in" do
      before do
        sign_in pro_user
      end

      it 'finds their own embargoed requests' do
        embargoed_request = FactoryBot.create(:embargoed_request,
                                              user: pro_user)
        post :preview, params: {
          outgoing_message: dummy_message,
          request_url_title: embargoed_request.url_title
        }
        expect(response).to be_successful
      end

      it 'raises an ActiveRecord::RecordNotFound error for other embargoed requests' do
        embargoed_request = FactoryBot.create(:embargoed_request)
        expect {
          post :preview, params: {
            outgoing_message: dummy_message,
            request_url_title: embargoed_request.url_title
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "displays a wrong user message when not logged in as the request owner" do
      sign_in FactoryBot.create(:user)
      post :preview, params: {
        outgoing_message: dummy_message,
        request_url_title: request.url_title,
        incoming_message_id: message_id
      }
      expect(response).to render_template('user/wrong_user')
    end

    context "logged in as the request owner" do
      before(:each) do
        sign_in request_user
      end

      it "displays the edit form with an error when the message body is blank" do
        post :preview, params: {
          request_url_title: request.url_title,
          outgoing_message: {
            body: "",
            what_doing: "normal_sort"
          },
          incoming_message_id: message_id
        }

        expect(response).to render_template("new")
        expect(response.body).to include("Please enter your follow up message")
      end

      it "shows a preview when input is good" do
        post :preview, params: {
                         outgoing_message: dummy_message,
                         request_url_title: request.url_title,
                         incoming_message_id: message_id,
                         preview: 1
                       }
        expect(response).to render_template('preview')
      end

      it "allows re-editing of a preview" do
        post :preview, params: {
                         outgoing_message: dummy_message,
                         request_url_title: request.url_title,
                         incoming_message_id: message_id,
                         reedit: "Re-edit this request"
                       }
        expect(response).to render_template('new')
      end
    end

    context 'when viewing a response for an embargoed request' do
      let(:pro_user) { FactoryBot.create(:pro_user) }
      let(:embargoed_request) do
        FactoryBot.create(:embargoed_request, user: pro_user)
      end

      it "sets @in_pro_area" do
        sign_in pro_user
        with_feature_enabled(:alaveteli_pro) do
          get :new, params: { request_url_title: embargoed_request.url_title }
          expect(assigns[:in_pro_area]).to eq true
        end
      end
    end
  end

  describe "POST #create" do
    let(:dummy_message) do
      { body: "What a useless response! You suck.",
        what_doing: 'normal_sort' }
    end

    before(:each) do
      sign_in request_user
    end

    shared_examples_for 'successful_followup_sent' do
      it 'sends the followup message' do
        post :create, params: {
                        outgoing_message: dummy_message,
                        request_url_title: request.url_title,
                        incoming_message_id: message_id
                      }

        # check it worked
        expect(deliveries.size).to eq(1)
        mail = deliveries.first
        expect(mail.body).to match(/What a useless response! You suck./)
        expect(mail.to_addrs.first.to_s).
          to eq(request.public_body.request_email)
      end
    end

    context "when not logged in" do
      before do
        sign_in nil
      end

      it 'raises an ActiveRecord::RecordNotFound error for an embargoed request' do
        embargoed_request = FactoryBot.create(:embargoed_request)
        expect {
          post :create, params: {
                          outgoing_message: dummy_message,
                          request_url_title: embargoed_request.url_title
                        }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to the signin page" do
        post :create, params: {
                        outgoing_message: dummy_message,
                        request_url_title: request.url_title,
                        incoming_message_id: message_id
                      }
        expect(response).
          to redirect_to(signin_url(token: get_last_post_redirect.token))
      end
    end

    context "when a pro user is logged in" do
      before do
        sign_in pro_user
      end

      it 'finds their own embargoed requests' do
        embargoed_request = FactoryBot.create(:embargoed_request,
                                              user: pro_user)
        expected_url = show_request_url(embargoed_request.url_title)
        post :create, params: {
                        outgoing_message: dummy_message,
                        request_url_title: embargoed_request.url_title
                      }
        expect(response).to redirect_to(expected_url)
      end

      it 'raises an ActiveRecord::RecordNotFound error for other embargoed requests' do
        embargoed_request = FactoryBot.create(:embargoed_request)
        expect {
          post :create, params: {
                          outgoing_message: dummy_message,
                          request_url_title: embargoed_request.url_title
                        }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "only allows the request owner to make a followup" do
      sign_in FactoryBot.create(:user)
      post :create, params: {
                      outgoing_message: dummy_message,
                      request_url_title: request.url_title,
                      incoming_message_id: message_id
                    }
      expect(response).to render_template('user/wrong_user')
    end

    it "gives an error and renders 'show_response' when a body isn't given" do
      post :create, params: {
                      outgoing_message: dummy_message.merge(body: ''),
                      request_url_title: request.url_title,
                      incoming_message_id: message_id
                    }

      expect(assigns[:outgoing_message].errors[:body]).
        to eq(["Please enter your follow up message"])
      expect(response).to render_template('new')
    end

    context 'a network error occurs while sending a followup' do
      def send_request
        post :create, params: {
               outgoing_message: dummy_message,
               request_url_title: request.url_title,
               incoming_message_id: message_id
             }
      end

      let(:outgoing_message) { request.reload.outgoing_messages.last }

      it_behaves_like 'NetworkSendErrors'
    end

    it_behaves_like 'successful_followup_sent'

    it "updates the status for successful followup sends" do
      post :create, params: {
                      outgoing_message: dummy_message,
                      request_url_title: request.url_title,
                      incoming_message_id: message_id
                    }

      expect(request.reload.described_state).to eq('waiting_response')
    end

    context 'the request is no longer open to "anybody"' do
      before do
        request.update(
          allow_new_responses_from: 'authority_only',
          reject_incoming_at_mta: true
        )
      end

      it 'reopens the parent request to new responses' do
        post :create, params: {
                        outgoing_message: dummy_message,
                        request_url_title: request.url_title,
                        incoming_message_id: message_id
                      }

        expect(request.reload.allow_new_responses_from).to eq('anybody')
        expect(request.reload.reject_incoming_at_mta).to eq(false)
      end

      it_behaves_like 'successful_followup_sent'
    end

    it "updates the event status for successful followup sends if the request is waiting clarification" do
      request.set_described_state('waiting_clarification')

      post :create, params: {
                      outgoing_message: dummy_message,
                      request_url_title: request.url_title,
                      incoming_message_id: message_id
                    }

      expect(request.reload.get_last_public_response_event.calculated_state).
        to eq('waiting_clarification')
    end

    it "redirects to the request page" do
      post :create, params: {
                      outgoing_message: dummy_message,
                      request_url_title: request.url_title,
                      incoming_message_id: message_id
                    }

      expect(response).
        to redirect_to(show_request_url(request.url_title))
    end

    it "displays the a confirmation once the message has been sent" do
      post :create, params: {
                      outgoing_message: dummy_message,
                      request_url_title: request.url_title,
                      incoming_message_id: message_id
                    }
      expect(flash[:notice]).
        to eq('Your follow up message has been sent on its way.')
    end

    it "displays an error if the request has been closed to new responses" do
      closed_request = FactoryBot.create(:info_request_with_incoming,
                                         user: request_user,
                                         allow_new_responses_from: "nobody")

      post :create,
           params: {
             outgoing_message: dummy_message,
             request_url_title: closed_request.url_title,
             incoming_message_id: closed_request.incoming_messages[0].id
           }
      expect(deliveries).to be_empty

      expect(response).to render_template('new')

      expect(flash.now[:error][:partial]).to eq("followup_not_sent")

      expect(response.body).
        to include('Your follow up has not been sent because this ' \
                   'request has been stopped to prevent spam.')
    end

    context "the same followup is submitted twice" do
      before(:each) do
        post :create, params: {
                        outgoing_message: dummy_message,
                        request_url_title: request.url_title,
                        incoming_message_id: message_id
                      }

        post :create, params: {
                        outgoing_message: dummy_message,
                        request_url_title: request.url_title,
                        incoming_message_id: message_id
                      }
      end

      it "displays the form with an error message" do
        expect(response).to render_template('new')
        expect(response.body).to include(
          'You previously submitted that exact follow up message for this ' \
          'request.'
        )
      end

      it "only delivers the message once" do
        expect(deliveries.size).to eq(1)
      end

      it "does not repeat the message sent text" do
        expect(response.body).
          not_to include('Your follow up message has been sent on its way')
      end
    end
  end
end
