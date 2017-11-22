# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::AccountRequestController do

  describe "#index" do
    it "renders index.html.erb" do
      with_feature_enabled :alaveteli_pro do
        get :index
        expect(response).to render_template('index')
      end
    end
  end

  describe "#create" do
    let(:account_request_params){ { email: 'test@localhost',
                                    reason: 'Have a look around',
                                    marketing_emails: 'yes',
                                    training_emails: 'no' } }

    it 'assigns the account request' do
      post :create, account_request: account_request_params
      expect(assigns[:account_request]).not_to be nil
    end

    context 'if the account request is valid' do

      it 'shows a notice' do
        post :create, account_request: account_request_params
        expect(flash[:notice]).not_to be nil
      end

      it 'redirects to the frontpage' do
        post :create, account_request: account_request_params
        expect(response).to redirect_to frontpage_path
      end

      it 'emails the pro contact address with the request' do
        post :create, account_request: account_request_params
        expect(ActionMailer::Base.deliveries.size).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to.first).to eq AlaveteliConfiguration::pro_contact_email
      end

    end

    context 'if the account request is not valid' do

      it 'renders the index template' do
        post :create, account_request: {}
        expect(response).to render_template('index')
      end

    end

  end

end
