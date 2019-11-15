# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminPublicBodyChangeRequestsController do
  let(:add_request) { FactoryBot.create(:add_body_request) }

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit, params: { id: add_request.id }
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
    end
  end
end
