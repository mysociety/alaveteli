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
    it 'closes the change request' do
      post :update, params: { id: add_request.id }
      expect(add_request.reload.is_open).to eq(false)
    end

    context 'close and respond' do
      it 'sends a response email to the user who requested the change' do
        post :update, params: { id: add_request.id,
                                response: 'Thanks but no',
                                subject: 'Your request' }
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.subject).to eq('Your request')
        expect(mail.to).to eq([add_request.get_user_email])
        expect(mail.body).to match(/Thanks but no/)
      end
    end

    context 'close' do
      it 'no email is sent to the user who requested the change' do
        post :update, params: { id: add_request.id }
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
      end
    end
  end
end
