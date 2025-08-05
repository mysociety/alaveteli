# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::AccountRequestController do

  describe "#index" do
    it "renders index.html.erb" do
      get :index
      expect(response).to render_template('index')
    end

    it 'sets the pro livery' do
      get :index
      expect(assigns[:in_pro_area]).to eq true
    end
  end

  describe "#create" do
    let(:account_request_params) { { email: 'test@localhost',
                                    reason: 'Have a look around',
                                    marketing_emails: 'yes',
                                    training_emails: 'no' } }

    it 'sets the pro livery' do
      post :create, params: { account_request: account_request_params }
      expect(assigns[:in_pro_area]).to eq true
    end

    it 'assigns the account request' do
      post :create, params: { account_request: account_request_params }
      expect(assigns[:account_request]).not_to be nil
    end

    context 'if the account request is valid' do

      it 'shows a notice' do
        post :create, params: { account_request: account_request_params }
        expect(flash[:notice]).not_to be nil
      end

      it 'redirects to the frontpage' do
        post :create, params: { account_request: account_request_params }
        expect(response).to redirect_to frontpage_path
      end

      it 'emails the pro contact address with the request' do
        post :create, params: { account_request: account_request_params }
        expect(ActionMailer::Base.deliveries.size).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to.first).to eq AlaveteliConfiguration::pro_contact_email
      end

    end

    context 'if the account request is not valid' do

      it 'renders the index template' do
        post :create, params: { account_request: {} }
        expect(response).to render_template('index')
      end

    end

    context 'when pro_pricing is enabled', feature: :pro_pricing do

      it 'redirects to the pro plans' do
        post :create
        expect(response).to redirect_to pro_plans_path
      end

    end

    context 'when pro_self_serve is enabled', feature: :pro_self_serve do

      context 'when current user is signed out' do

        it 'redirects to sign in' do
          post :create
          expect(response).to redirect_to(
            signin_path(token: get_last_post_redirect.token)
          )
        end

      end

      context 'when current user is signed in' do

        let(:user) { FactoryBot.create(:user) }

        before do
          session[:user_id] = user.id
          allow(controller).to receive(:current_user).and_return(user)
        end

        it 'adds the pro role' do
          post :create
          expect(user.is_pro?).to eq(true)
        end

        it 'welcomes the new user' do
          post :create
          expect(flash[:notice]).to eq('Welcome to Alaveteli Professional!')
        end

        it 'sets new_pro_user in flash' do
          post :create
          expect(flash[:new_pro_user]).to be true
        end

        it 'redirects to the pro dashboard' do
          post :create
          expect(response).to redirect_to(alaveteli_pro_dashboard_path)
        end

      end

    end

  end

end
