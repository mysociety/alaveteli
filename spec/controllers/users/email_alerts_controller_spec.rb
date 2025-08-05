# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::EmailAlertsController do
  describe 'GET #destroy' do
    context 'with a valid token' do
      let(:token) { 'valid' }

      before do
        allow(User::EmailAlerts).
          to receive(:disable_by_token).with(token).and_return(true)
        get :destroy, params: { token: token }
      end

      it 'renders the destroy template' do
        expect(response).to render_template(:destroy)
      end

      it 'is successful' do
        expect(response.status).to eq(200)
      end
    end

    context 'with an escaped token' do
      let(:token) { CGI.escape('123=') }

      it 'unescapes the token' do
        expect(User::EmailAlerts).to receive(:disable_by_token).with('123=')
        get :destroy, params: { token: token }
      end
    end

    context 'with an invalid token' do
      before { get :destroy, params: { token: 'invalid' } }

      it 'tells the user the token was invalid' do
        expect(flash[:error]).to eq('Invalid token')
      end

      it 'redirects to the homepage' do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
