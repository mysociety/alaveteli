# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminPublicBodyChangeRequestsController do

  describe 'GET #edit' do
    it 'renders the edit template' do
      change_request = FactoryBot.create(:add_body_request)
      get :edit, params: { id: change_request.id }
      expect(response).to render_template('edit')
    end
  end

  describe 'PUT #update' do
    before do
      @change_request = FactoryBot.create(:add_body_request)
    end

    it 'closes the change request' do
      post :update, params: { id: @change_request.id }
      expect(PublicBodyChangeRequest.find(@change_request.id).is_open).
        to eq(false)
    end

    context 'close and respond' do
      it 'sends a response email to the user who requested the change' do
        post :update, params: { id: @change_request.id,
                                response: 'Thanks but no',
                                subject: 'Your request' }
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.subject).to eq('Your request')
        expect(mail.to).to eq([@change_request.get_user_email])
        expect(mail.body).to match(/Thanks but no/)
      end
    end

    context 'close' do
      it 'no email is sent to the user who requested the change' do
        post :update, params: { id: @change_request.id }
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
      end
    end
  end
end
