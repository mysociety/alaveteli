require 'spec_helper'

RSpec.describe AdminOutgoingMessageController do

  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  describe 'GET #edit' do

    before { sign_in(admin_user) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:outgoing) { info_request.outgoing_messages.first }

    it 'should be successful' do
      get :edit, params: { :id => outgoing.id }
      expect(response).to be_successful
    end

    it 'should assign the outgoing message to the view' do
      get :edit, params: { :id => outgoing.id }
      expect(assigns[:outgoing_message]).to eq(outgoing)
    end

    context 'when the message is the initial outgoing message' do

      it 'sets is_initial_message to true' do
        get :edit, params: { :id => outgoing.id }
        expect(assigns[:is_initial_message]).to eq(true)
      end

    end

    context 'when the message is not initial outgoing message' do

      it 'sets is_initial_message to false' do
        outgoing = FactoryBot.create(:new_information_followup,
                                     :info_request => info_request)
        get :edit, params: { :id => outgoing.id }
        expect(assigns[:is_initial_message]).to eq(false)
      end

    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :edit, params: { id: outgoing }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'is successful' do
          get :edit, params: { id: outgoing }
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'DELETE #destroy' do

    before { sign_in(admin_user) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:outgoing) do
      FactoryBot.create(:new_information_followup,
                        :info_request => info_request)
    end

    it 'finds the outgoing message' do
      delete :destroy, params: { :id => outgoing.id }
      expect(assigns[:outgoing_message]).to eq(outgoing)
    end

    context 'successfully destroying the message' do

      it 'destroys the message' do
        delete :destroy, params: { :id => outgoing.id }
        expect(assigns[:outgoing_message]).to_not be_persisted
      end

      it 'logs an event on the info request' do
        delete :destroy, params: { :id => outgoing.id }
        expect(info_request.reload.last_event.event_type).
          to eq('destroy_outgoing')
      end

      it 'informs the user' do
        delete :destroy, params: { :id => outgoing.id }
        expect(flash[:notice]).to eq('Outgoing message successfully destroyed.')
      end

      it 'redirects to the admin request page' do
        delete :destroy, params: { :id => outgoing.id }
        expect(response).to redirect_to(admin_request_url(info_request))
      end

    end

    context 'unsuccessfully destroying the message' do
      before do
        allow_any_instance_of(OutgoingMessage).
          to receive(:destroy).and_return(false)
      end

      it 'does not destroy the message' do
        delete :destroy, params: { :id => outgoing.id }
        expect(assigns[:outgoing_message]).to be_persisted
      end

      it 'informs the user' do
        delete :destroy, params: { :id => outgoing.id }
        expect(flash[:error]).to eq('Could not destroy the outgoing message.')
      end

      it 'redirects to the outgoing message edit page' do
        delete :destroy, params: { :id => outgoing.id }
        expect(response).
          to redirect_to(edit_admin_outgoing_message_path(outgoing))
      end

    end

    context 'when the message is the initial outgoing message' do

      it 'sets is_initial_message to true' do
        outgoing = FactoryBot.create(:initial_request)
        delete :destroy, params: { :id => outgoing.id }
        expect(assigns[:is_initial_message]).to eq(true)
      end

      it 'prevents the destruction of the message' do
        outgoing = FactoryBot.create(:initial_request)
        delete :destroy, params: { :id => outgoing.id }
        expect(assigns[:outgoing_message]).to be_persisted
      end

    end

    context 'when the message is not initial outgoing message' do

      it 'sets is_initial_message to false' do
        delete :destroy, params: { :id => outgoing.id }
        expect(assigns[:is_initial_message]).to eq(false)
      end

      it 'allows the destruction of the message' do
        delete :destroy, params: { :id => outgoing.id }
        expect(assigns[:outgoing_message]).to_not be_persisted
      end

    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            delete :destroy, params: { id: outgoing }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'redirects to request admin' do
          delete :destroy, params: { id: outgoing }
          expect(response).to redirect_to(admin_request_url(info_request))
        end
      end
    end
  end

  describe 'PUT #update' do

    before { sign_in(admin_user) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:outgoing) { info_request.outgoing_messages.first }
    let(:default_params) do
      {
        id: outgoing.id,
        outgoing_message: {
          prominence: 'hidden',
          prominence_reason: 'dull',
          body: 'changed body',
          tag_string: 'foo'
        }
      }
    end

    def make_request(params = default_params)
      post :update, params: params
    end

    it 'should save a change to the body of the message' do
      make_request
      outgoing.reload
      expect(outgoing.body).to eq('changed body')
    end

    it 'should save the prominence of the message' do
      make_request
      outgoing.reload
      expect(outgoing.prominence).to eq('hidden')
    end

    it 'should save a prominence reason for the message' do
      make_request
      outgoing.reload
      expect(outgoing.prominence_reason).to eq('dull')
    end

    it 'should save a tag string for the message' do
      make_request
      outgoing.reload
      expect(outgoing.tag_string).to eq('foo')
    end

    it 'should log an "edit_outgoing" event on the info_request' do
      allow(@controller).to receive(:admin_current_user).and_return("Admin user")
      make_request
      info_request.reload
      last_event = info_request.info_request_events.last
      expect(last_event.event_type).to eq('edit_outgoing')
      expect(last_event.params).to eq(
        outgoing_message: { gid: outgoing.to_global_id.to_s },
        editor: 'Admin user',
        old_body: 'Some information please',
        body: 'changed body',
        old_prominence: 'normal',
        prominence: 'hidden',
        old_prominence_reason: nil,
        prominence_reason: 'dull',
        old_tag_string: '',
        tag_string: 'foo'
      )
    end

    it 'should expire the file cache for the info request' do
      info_request = FactoryBot.create(:info_request)
      allow_any_instance_of(OutgoingMessage).to receive(:info_request) { info_request }

      outgoing = FactoryBot.create(:initial_request, :info_request => info_request)

      expect(info_request).to receive(:expire)

      params = default_params.dup
      params[:id] = outgoing.id
      make_request(params)
    end

    context 'if the outgoing message saves correctly' do

      it 'should redirect to the admin info request view' do
        make_request
        expect(response).to redirect_to admin_request_url(info_request)
      end

      it 'should show a message that the incoming message has been updated' do
        make_request
        expect(flash[:notice]).to eq('Outgoing message successfully updated.')
      end

    end

    context 'if the incoming message is not valid' do

      it 'should render the edit template' do
        make_request({:id => outgoing.id,
                      :outgoing_message => {:prominence => 'fantastic',
                                            :prominence_reason => 'dull',
                                            :body => 'Some information please'}})
        expect(response).to render_template("edit")
      end

    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect { make_request }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'redirects to request admin' do
          make_request
          expect(response).to redirect_to(admin_request_url(info_request))
        end
      end
    end
  end

  describe 'POST #resend' do
    before { sign_in(admin_user) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:outgoing) { info_request.outgoing_messages.first }

    it 'redirects to the admin show request page' do
      post :resend, params: { id: outgoing.id }
      expect(response).
        to redirect_to(admin_request_path(info_request))
    end

    it 'logs the message resend' do
      post :resend, params: { id: outgoing.id }
      expect(info_request.reload.last_event.event_type).to eq 'resent'
    end

    it 'raises an error if given an unexpected message type' do
      outgoing.update_attribute(:message_type, 'invalid')
      expect { post :resend, params: { id: outgoing.id } }.
        to raise_error(RuntimeError)
    end

    it 'changes info_request#updated_at' do
      travel_to(1.day.ago) { info_request }
      expect { post :resend, params: { id: outgoing.id } }.
        to change { info_request.reload.updated_at.to_date }.
          from(1.day.ago.to_date).to(Time.zone.now.to_date)
    end

    it 'reopens closed requests to new responses' do
      info_request.update(
        allow_new_responses_from: 'nobody',
        reject_incoming_at_mta: true
      )

      post :resend, params: { id: outgoing.id }
      expect(info_request.reload.allow_new_responses_from).
        to eq('anybody')
      expect(info_request.reload.reject_incoming_at_mta).to eq(false)
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            post :resend, params: { id: outgoing }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'redirects to request admin' do
          post :resend, params: { id: outgoing }
          expect(response).to redirect_to(admin_request_url(info_request))
        end
      end
    end
  end

end
