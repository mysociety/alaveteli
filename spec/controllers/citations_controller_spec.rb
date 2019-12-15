require 'spec_helper'

RSpec.describe CitationsController, type: :controller do
  before do
    allow(controller).to receive(:site_name).and_return('SITE')
  end

  describe 'GET new' do
    context 'logged in' do
      let(:user) { FactoryBot.create(:user) }
      before { session[:user_id] = user.id }

      it 'should be successful' do
        get :new, params: { url_title: 'request_title' }
        expect(response).to be_successful
      end
    end

    context 'logged out' do
      it 'redirects to sign in form' do
        get :new, params: { url_title: 'request_title' }
        expect(response.status).to eq 302
      end

      it 'saves post redirect' do
        get :new, params: { url_title: 'request_title' }

        post_redirect = get_last_post_redirect
        expect(post_redirect.uri).to eq '/request/request_title/citations/new'
        expect(post_redirect.reason_params).to eq(
          web: 'To add a citation',
          email: 'Then you can add citations',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end

  describe 'POST create' do
    context 'logged in' do
      let(:user) { FactoryBot.create(:user) }
      before { session[:user_id] = user.id }

      it 'should be successful' do
        post :create, params: { url_title: 'request_title' }
        expect(response).to be_successful
      end
    end

    context 'logged out' do
      it 'redirects to sign in form' do
        post :create, params: { url_title: 'request_title' }
        expect(response.status).to eq 302
      end

      it 'saves post redirect' do
        post :create, params: { url_title: 'request_title' }

        post_redirect = get_last_post_redirect
        expect(post_redirect.uri).to eq '/request/request_title/citations'
        expect(post_redirect.reason_params).to eq(
          web: 'To add a citation',
          email: 'Then you can add citations',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end
end
