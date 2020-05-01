require 'spec_helper'

RSpec.describe ClassificationsController, type: :controller do
  describe 'POST create' do
    describe 'if the request is external' do
      let(:external_request) { FactoryBot.create(:external_request) }

      it 'should redirect to the request page' do
        post :create, params: { url_title: external_request.url_title }
        expect(response).to redirect_to(
          show_request_path(external_request.url_title)
        )
      end
    end

    describe 'when the request is internal' do
      let(:info_request) { FactoryBot.create(:info_request) }

      def post_status(status, message: nil)
        classification = { described_state: status }
        classification[:message] = message if message

        post :create, params: {
          classification: classification,
          url_title: info_request.url_title,
          last_info_request_event_id: info_request.
            last_event_id_needing_description
        }
      end

      context 'when the request is embargoed' do
        let(:info_request) { FactoryBot.create(:embargoed_request) }

        it 'should raise ActiveRecord::NotFound' do
          expect { post_status('rejected') }.
            to raise_error ActiveRecord::RecordNotFound
        end
      end

      it 'should require login' do
        post_status('rejected')
        expect(response).to redirect_to(
          signin_path(token: get_last_post_redirect.token)
        )
      end

      it 'should not classify the request if logged in as the wrong user' do
        session[:user_id] = FactoryBot.create(:user).id
        post_status('rejected')
        expect(response).to render_template('user/wrong_user')
      end

      describe 'when the request is old and unclassified' do
        let(:info_request) { FactoryBot.create(:old_unclassified_request) }

        describe 'when the user is not logged in' do
          before do
            session[:user_id] = nil
          end

          it 'should require login' do
            post_status('rejected')
            expect(response).to redirect_to(
              signin_path(token: get_last_post_redirect.token)
            )
          end
        end

        describe 'when the user is logged in as a different user' do
          let(:other_user) { FactoryBot.create(:user) }

          before do
            session[:user_id] = other_user.id
          end

          it 'should classify the request' do
            post_status('rejected')
            expect(info_request.reload.described_state).to eq('rejected')
          end

          it 'should log a status update event' do
            expected_params = { user_id: other_user.id,
                                old_described_state: 'waiting_response',
                                described_state: 'rejected' }
            post_status('rejected')
            last_event = info_request.reload.info_request_events.last
            expect(last_event.params).to eq expected_params
          end

          it 'should send an email to the requester letting them know someone
              has updated the status of their request' do
            post_status('rejected')
            deliveries = ActionMailer::Base.deliveries
            expect(deliveries.size).to eq(1)
            expect(deliveries.first.subject).
              to match('Someone has updated the status of your request')
          end

          it 'should redirect to the request page' do
            post_status('rejected')
            expect(response).to redirect_to(
              show_request_path(info_request.url_title)
            )
          end

          it 'should show a message thanking the user for a good deed' do
            post_status('rejected')
            expect(flash[:notice]).to eq('Thank you for updating this request!')
          end

          context 'playing the classification game' do
            before :each do
              session[:request_game] = true
            end

            it 'should continue the game after classifying a request' do
              post_status('rejected')
              expect(response).to redirect_to(categorise_play_url)
            end

            it 'shows a message thanking the user for a good deed' do
              post_status('rejected')
              expect(flash[:notice][:partial]).to eq(
                'request_game/thank_you.html.erb'
              )
              expect(flash[:notice][:locals]).to include(
                info_request_title: info_request.title
              )
            end
          end

          context 'when the new status is "requires_admin"' do
            it 'should send a mail to admins saying that the response ' \
               'requires admin and one to the requester noting the status ' \
               'change' do
              post_status('requires_admin', message: 'a message')
              deliveries = ActionMailer::Base.deliveries
              expect(deliveries.size).to eq(2)
              requires_admin_mail = deliveries.first
              status_update_mail = deliveries.second
              expect(requires_admin_mail.subject).
                to match(/FOI response requires admin/)
              expect(requires_admin_mail.to).
                to match([AlaveteliConfiguration.contact_email])
              expect(status_update_mail.subject).
                to match('Someone has updated the status of your request')
              expect(status_update_mail.to).
                to match([info_request.user.email])
            end

            context "if the params don't include a message" do
              it 'redirects to the message url' do
                post_status('requires_admin')
                expect(response).to redirect_to(
                  message_classification_url(
                    url_title: info_request.url_title,
                    described_state: 'requires_admin'
                  )
                )
              end
            end
          end
        end
      end

      describe 'when logged in as an admin user who is not the actual ' \
               'requester' do
        let(:admin_user) { FactoryBot.create(:admin_user) }
        let(:info_request) { FactoryBot.create(:info_request) }

        before do
          session[:user_id] = admin_user.id
        end

        it 'should update the status of the request' do
          post_status('rejected')
          expect(info_request.reload.described_state).to eq('rejected')
        end

        it 'should log a status update event' do
          expected_params = { user_id: admin_user.id,
                              old_described_state: 'waiting_response',
                              described_state: 'rejected' }
          post_status('rejected')
          last_event = info_request.reload.info_request_events.last
          expect(last_event.params).to eq expected_params
        end

        it 'should record a classification' do
          post_status('rejected')
          last_event = info_request.reload.info_request_events.last
          classification = RequestClassification.order('created_at DESC').last
          expect(classification.user_id).to eq(admin_user.id)
          expect(classification.info_request_event).to eq(last_event)
        end

        it 'should send an email to the requester letting them know someone has
            updated the status of their request' do
          mail_mock = double('mail')
          allow(mail_mock).to receive :deliver_now
          expect(RequestMailer).to receive(:old_unclassified_updated).
            and_return(mail_mock)
          post_status('rejected')
        end

        it 'should redirect to the request page' do
          post_status('rejected')
          expect(response).to redirect_to(
            show_request_path(info_request.url_title)
          )
        end

        it 'should show a message thanking the user for a good deed' do
          post_status('rejected')
          expect(flash[:notice]).to eq('Thank you for updating this request!')
        end
      end

      describe 'when logged in as an admin user who is also the actual ' \
               'requester' do
        let(:admin_user) { FactoryBot.create(:admin_user) }
        let(:info_request) do
          FactoryBot.create(:info_request, user: admin_user)
        end

        before do
          session[:user_id] = admin_user.id
        end

        it 'should update the status of the request' do
          post_status('rejected')
          expect(info_request.reload.described_state).to eq('rejected')
        end

        it 'should log a status update event' do
          expected_params = { user_id: admin_user.id,
                              old_described_state: 'waiting_response',
                              described_state: 'rejected' }
          post_status('rejected')
          last_event = info_request.reload.info_request_events.last
          expect(last_event.params).to eq expected_params
        end

        it 'should not send an email to the requester letting them know ' \
           'someone has updated the status of their request' do
          expect(RequestMailer).not_to receive(:old_unclassified_updated)
          post_status('rejected')
        end

        it 'should show advice for the new state' do
          post_status('rejected')
          expect(flash[:notice][:partial]).to eq(
            'request/describe_notices/rejected'
          )
        end

        it 'should redirect to the unhappy page' do
          post_status('rejected')
          expect(response).to redirect_to(
            help_unhappy_path(info_request.url_title)
          )
        end
      end

      describe 'when logged in as the requestor' do
        let(:info_request) do
          FactoryBot.create(:info_request, awaiting_description: true)
        end

        before do
          session[:user_id] = info_request.user_id
        end

        it 'should let you know when you forget to select a status' do
          post :create, params: {
            url_title: info_request.url_title,
            last_info_request_event_id: info_request.
              last_event_id_needing_description
          }
          expect(response).to redirect_to(
            show_request_url(url_title: info_request.url_title)
          )
          expect(flash[:error]).to eq(
            'Please choose whether or not you got some of the information ' \
            'that you wanted.'
          )
        end

        it 'should not change the status if the request has changed while ' \
           'viewing it' do
          post :create, params: {
            classification: { described_state: 'rejected' },
            url_title: info_request.url_title,
            last_info_request_event_id: 1
          }
          expect(response).to redirect_to(
            show_request_url(url_title: info_request.url_title)
          )
          expect(flash[:error]).to match(
            /The request has been updated since you originally loaded this page/
          )
        end

        it 'should successfully classify response' do
          post_status('rejected')
          expect(response).to redirect_to(
            help_unhappy_path(info_request.url_title)
          )
          info_request.reload
          expect(info_request.awaiting_description).to eq(false)
          expect(info_request.described_state).to eq('rejected')
          expect(info_request.info_request_events.last.event_type).to eq(
            'status_update'
          )
          expect(info_request.info_request_events.last.calculated_state).to eq(
            'rejected'
          )
        end

        it 'should log a status update event' do
          expected_params = { user_id: info_request.user_id,
                              old_described_state: 'waiting_response',
                              described_state: 'rejected' }
          post_status('rejected')
          last_event = info_request.reload.info_request_events.last
          expect(last_event.params).to eq expected_params
        end

        it 'should not send an email to the requester letting them know someone
            has updated the status of their request' do
          expect(RequestMailer).not_to receive(:old_unclassified_updated)
          post_status('rejected')
        end

        it 'should go to the page asking for more information when ' \
           'classified as requires_admin' do
          post_status('requires_admin')
          expect(response).to redirect_to(
            message_classification_url(url_title: info_request.url_title,
                                       described_state: 'requires_admin')
          )

          info_request.reload
          expect(info_request.described_state).not_to eq('requires_admin')
          expect(ActionMailer::Base.deliveries).to be_empty
        end

        context 'message is included when classifying as requires_admin' do
          it 'should send an email including the message' do
            post_status('requires_admin', message: 'Something weird happened')
            deliveries = ActionMailer::Base.deliveries
            expect(deliveries.size).to eq(1)
            mail = deliveries[0]
            expect(mail.body).to match(/as needing admin/)
            expect(mail.body).to match(/Something weird happened/)
          end
        end

        it 'should show advice for the new state' do
          post_status('rejected')
          expect(flash[:notice][:partial]).to eq(
            'request/describe_notices/rejected'
          )
        end

        it 'should redirect to the unhappy page' do
          post_status('rejected')
          expect(response).to redirect_to(
            help_unhappy_path(info_request.url_title)
          )
        end

        it 'knows about extended states' do
          custom_states = Rails.root.join('spec', 'models', 'customstates')
          InfoRequest.send(:require, custom_states)
          InfoRequest.send(:include, InfoRequestCustomStates)
          InfoRequest.class_eval('@@custom_states_loaded = true')
          described_class.send(:require, custom_states)
          described_class.send(:include, RequestControllerCustomStates)
          described_class.class_eval('@@custom_states_loaded = true')
          allow(Time).to receive(:now).
            and_return(Time.utc(2007, 11, 10, 0o0, 0o1))
          post_status('deadline_extended')
          expect(flash[:notice]).to eq(
            'Authority has requested extension of the deadline.'
          )
        end
      end

      describe 'after a successful status update by the request owner' do
        render_views

        let(:info_request) { FactoryBot.create(:info_request) }

        before do
          session[:user_id] = info_request.user_id
        end

        context 'when status is updated to "waiting_response"' do
          it 'should redirect to the "request url"' do
            post_status('waiting_response')
            expect(response).to redirect_to(
              show_request_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('waiting_response')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/waiting_response'
            )
          end
        end

        context 'when status is updated to "waiting_response" and overdue' do
          let(:info_request) { FactoryBot.create(:overdue_request) }

          it 'should redirect to the "request url"' do
            post_status('waiting_response')
            expect(response).to redirect_to(
              show_request_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('waiting_response')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/waiting_response_overdue'
            )
          end
        end

        context 'when status is updated to "waiting_response" and very ' \
                'overdue' do
          let(:info_request) { FactoryBot.create(:very_overdue_request) }

          it 'should redirect to the "request url"' do
            post_status('waiting_response')
            expect(response).to redirect_to(
              help_unhappy_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('waiting_response')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/waiting_response_very_overdue'
            )
          end
        end

        context 'when status is updated to "not held"' do
          it 'should redirect to the "request url"' do
            post_status('not_held')
            expect(response).to redirect_to(
              show_request_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('not_held')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/not_held'
            )
          end
        end

        context 'when status is updated to "successful"' do
          it 'should redirect to the "request url"' do
            post_status('successful')
            expect(response).to redirect_to(
              show_request_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('successful')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/successful'
            )
          end
        end

        context 'when status is updated to "waiting clarification"' do
          context 'when there is a last response' do
            let(:info_request) do
              FactoryBot.create(:info_request_with_incoming)
            end

            it 'should redirect to the "response url"' do
              post_status('waiting_clarification')
              expect(response).to redirect_to(
                new_request_incoming_followup_path(
                  request_id: info_request.id,
                  incoming_message_id: info_request.get_last_public_response.id
                )
              )
            end

            it 'should show a message' do
              post_status('waiting_clarification')
              expect(flash[:notice][:partial]).to eq(
                'request/describe_notices/waiting_clarification'
              )
            end
          end

          context 'when there are no events needing description' do
            it 'should redirect to the "followup no incoming url"' do
              post_status('waiting_clarification')
              expect(response).to redirect_to(
                new_request_followup_path(
                  request_id: info_request.id,
                  incoming_message_id: nil
                )
              )
            end

            it 'should show a message' do
              post_status('waiting_clarification')
              expect(flash[:notice][:partial]).to eq(
                'request/describe_notices/waiting_clarification'
              )
            end
          end
        end

        context 'when status is updated to "rejected"' do
          it 'should redirect to the "unhappy url"' do
            post_status('rejected')
            expect(response).to redirect_to(
              help_unhappy_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('rejected')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/rejected'
            )
          end
        end

        context 'when status is updated to "partially successful"' do
          it 'should redirect to the "unhappy url"' do
            post_status('partially_successful')
            expect(response).to redirect_to(
              help_unhappy_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('partially_successful')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/partially_successful'
            )
          end
        end

        context 'when status is updated to "gone postal"' do
          let(:info_request) { FactoryBot.create(:info_request_with_incoming) }

          it 'should redirect to the "respond to last" url' do
            post_status('gone_postal')
            expect(response).to redirect_to(
              new_request_incoming_followup_path(
                request_id: info_request.id,
                incoming_message_id: info_request.get_last_public_response.id,
                gone_postal: 1
              )
            )
          end

          it 'should not show a message' do
            post_status('gone_postal')
            expect(flash[:notice]).to be_nil
          end
        end

        context 'when status updated to "internal review"' do
          it 'should redirect to the "request url"' do
            post_status('internal_review')
            expect(response).to redirect_to(
              show_request_path(info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('internal_review')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/internal_review'
            )
          end
        end

        context 'when status is updated to "requires admin"' do
          it 'should redirect to the "request url"' do
            post_status('requires_admin', message: 'A message')
            expect(response).to redirect_to(
              show_request_url(url_title: info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('requires_admin', message: 'A message')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/requires_admin'
            )
          end

          context "if the params don't include a message" do
            it 'redirects to the classification message action' do
              post_status('requires_admin')
              expect(response).to redirect_to(
                message_classification_url(
                  url_title: info_request.url_title,
                  described_state: 'requires_admin'
                )
              )
            end

            it 'should not show a message' do
              post_status('gone_postal')
              expect(flash[:notice]).to be_nil
            end
          end
        end

        context 'when status is updated to "error message"' do
          it 'should redirect to the "request url"' do
            post_status('error_message', message: 'A message')
            expect(response).to redirect_to(
              show_request_url(url_title: info_request.url_title)
            )
          end

          it 'should show a message' do
            post_status('error_message', message: 'A message')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/error_message'
            )
          end

          context "if the params don't include a message" do
            it 'redirects to the classification message action' do
              post_status('error_message')
              expect(response).to redirect_to(
                message_classification_url(
                  url_title: info_request.url_title,
                  described_state: 'error_message'
                )
              )
            end

            it 'should not show a message' do
              post_status('gone_postal')
              expect(flash[:notice]).to be_nil
            end
          end
        end

        context 'when status is updated to "user_withdrawn"' do
          let(:info_request) { FactoryBot.create(:info_request_with_incoming) }

          it 'should redirect to the "respond to last" url' do
            post_status('user_withdrawn')
            expect(response).to redirect_to(
              new_request_incoming_followup_path(
                request_id: info_request.id,
                incoming_message_id: info_request.get_last_public_response.id
              )
            )
          end

          it 'should show a message' do
            post_status('user_withdrawn')
            expect(flash[:notice][:partial]).to eq(
              'request/describe_notices/user_withdrawn'
            )
          end
        end
      end
    end
  end

  describe 'GET #message' do
    include_examples 'adding classification message action'

    let(:info_request) { FactoryBot.create(:info_request_with_incoming) }

    def run_action
      get :message, params: {
        url_title: info_request.url_title,
        described_state: 'error_message'
      }
    end

    it 'assigns the last info request event id to the view' do
      run_action
      expect(assigns[:last_info_request_event_id]).to eq(
        info_request.last_event_id_needing_description
      )
    end

    context 'when the request is embargoed' do
      let(:info_request) { FactoryBot.create(:embargoed_request) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { run_action }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
