# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::PlansController do

  describe 'GET #show' do

    context 'without a signed-in user' do

      before do
        get :show, id: 'pro'
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'with a signed-in user' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        session[:user_id] = user.id
        get :show, id: 'pro'
      end

      it 'renders the plan page' do
        expect(response).to render_template(:show)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

    end

  end

end
