require 'spec_helper'

RSpec.describe AdminPublicBodyChangeRequestsController do
  let(:add_request) { FactoryBot.create(:add_body_request) }

  describe 'GET #edit' do
    before do
      get :edit, params: { id: add_request.id }
    end

    it 'sets the page title' do
      expect(assigns[:title]).to eq('Close change request')
    end

    it 'renders the edit template' do
      expect(response).to render_template('edit')
    end
  end

  describe 'PUT #update' do
    before do
      post :update, params: params
    end

    context 'close and respond' do
      let(:params) do
        { id: add_request.id,
          response: 'Thanks but no',
          subject: 'Your request' }
      end

      it 'closes the change request' do
        expect(add_request.reload.is_open).to eq(false)
      end

      it 'sends a response email to the user who requested the change' do
        deliveries = ActionMailer::Base.deliveries
        mail = deliveries.first

        expect(deliveries.size).to eq(1)
        expect(mail.subject).to eq('Your request')
        expect(mail.to).to eq([add_request.get_user_email])
        expect(mail.body).to match(/Thanks but no/)
      end

      it 'notifies the admin the request is closed and user has been emailed' do
        msg =
          'The change request has been closed and the user has been notified'

        expect(flash[:notice]).to eq(msg)
      end

      it { is_expected.to redirect_to(admin_general_index_path) }
    end

    context 'close' do
      let(:params) do
        { id: add_request.id }
      end

      it 'closes the change request' do
        expect(add_request.reload.is_open).to eq(false)
      end

      it 'no email is sent to the user who requested the change' do
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it 'notifies the admin the request is closed' do
        expect(flash[:notice]).to eq('The change request has been closed')
      end

      it { is_expected.to redirect_to(admin_general_index_path) }
    end
  end
end
