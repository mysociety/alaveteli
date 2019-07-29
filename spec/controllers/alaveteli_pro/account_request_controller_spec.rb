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

    it 'assigns public beta variable' do
      get :index
      expect(assigns[:public_beta]).to eq true
    end

    it 'assigns pro site name variable' do
      get :index
      expect(assigns(:pro_site_name)).to eq AlaveteliConfiguration.pro_site_name
    end
  end

  describe "#new" do
    it "renders index.html.erb" do
      get :new
      expect(response).to render_template('index')
    end

    it 'sets the pro livery' do
      get :new
      expect(assigns[:in_pro_area]).to eq true
    end

    it 'does not assign public beta variable' do
      get :new
      expect(assigns[:public_beta]).to_not eq true
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

  end

end
