# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ReportsController do

  describe 'POST #create' do
    let(:info_request){ FactoryGirl.create(:info_request) }
    let(:user){ FactoryGirl.create(:user) }

    context "when reporting a request when not logged in" do
      it "should only allow logged-in users to report requests" do
        post :create, :request_id => info_request.url_title,
                      :reason => "my reason"
        expect(flash[:notice]).to match(/You need to be logged in/)
        expect(response)
          .to redirect_to show_request_path(:url_title =>
                                              info_request.url_title)
      end
    end

    context "when reporting a request (logged in)" do
      before do
        session[:user_id] = user.id
      end

      it "should 404 for non-existent requests" do
        expect {
          post :create, :request_id => "hjksfdhjk_louytu_qqxxx"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should 404 for embargoed requests' do
        info_request = FactoryGirl.create(:embargoed_request)
        expect {
          post :create, :request_id => info_request.url_title
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should mark a request as having been reported" do
        expect(info_request.attention_requested).to eq(false)

        post :create, :request_id => info_request.url_title,
                      :reason => "my reason"
        expect(response)
          .to redirect_to show_request_path(:url_title =>
                                              info_request.url_title)

        info_request.reload
        expect(info_request.attention_requested).to eq(true)
        expect(info_request.described_state).to eq("attention_requested")
      end

      it "should not allow a request to be reported twice" do
        post :create, :request_id => info_request.url_title,
                      :reason => "my reason"
        expect(response)
          .to redirect_to show_request_url(:url_title =>
                                             info_request.url_title)

        post :create, :request_id => info_request.url_title,
                      :reason => "my reason"
        expect(response)
          .to redirect_to show_request_url(:url_title =>
                                             info_request.url_title)
        expect(flash[:notice]).to match(/has already been reported/)
      end

      it "should send an email from the reporter to admins" do
        post :create, :request_id => info_request.url_title,
                      :reason => "my reason",
                      :message => "It's just not"
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.subject).to match(/attention_requested/)
        expect(mail.header['Reply-To'].to_s).to include(user.email)
        expect(mail.body).to include(user.name)
        expect(mail.body)
          .to include("Reason: my reason\n\nIt's just not")
      end

      it "should force the user to pick a reason" do
        post :create, :request_id => info_request.url_title,
                      :reason => ""
        expect(response).to render_template("new")
        expect(flash[:error]).to eq("Please choose a reason")
      end

    end
  end

  describe "GET #new" do
    let(:info_request){ FactoryGirl.create(:info_request) }
    let(:user){ FactoryGirl.create(:user) }

    context "not logged in" do
      it "should require the user to be logged in" do
        get :new, :request_id => info_request.url_title
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end
    end

    context "logged in" do
      before :each do
        session[:user_id] = user.id
      end

      it "should show the form" do
        get :new, :request_id => info_request.url_title
        expect(response).to render_template("new")
      end

      it "should 404 for non-existent requests" do
        expect {
          get :new, :request_id => "hjksfdhjk_louytu_qqxxx"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should 404 for embargoed requests' do
        info_request = FactoryGirl.create(:embargoed_request)
        expect {
          get :new, :request_id => info_request.url_title
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

  end

end
