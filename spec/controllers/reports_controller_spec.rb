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

      it "finds the expected request" do
        post :create, :request_id => info_request.url_title,
                      :reason => "my reason"

        expect(assigns(:info_request)).to eq(info_request)
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

      it "sets the flash message" do
        expected = "This request has been reported for administrator attention"

        post :create, :request_id => info_request.url_title,
                      :reason => "my reason",
                      :message => "It's just not"

        expect(flash[:notice]).to eq(expected)
      end

      it "should force the user to pick a reason" do
        post :create, :request_id => info_request.url_title,
                      :reason => ""
        expect(response).to render_template("new")
        expect(flash[:error]).to eq("Please choose a reason")
      end

    end

    context "when reporting a comment (logged in)" do
      before do
        session[:user_id] = user.id
      end

      let(:comment) do
        FactoryGirl.create(:comment, :info_request => info_request)
      end

      it "finds the expected request" do
        post :create, :request_id => info_request.url_title,
                      :reason => "my reason"

        expect(assigns(:info_request)).to eq(info_request)
      end

      it "should mark the comment as having been reported" do
        expect(comment.attention_requested).to eq(false)

        post :create, :request_id => info_request.url_title,
                      :comment_id => comment.id,
                      :reason => "my reason"
        expect(response)
          .to redirect_to show_request_path(:url_title =>
                                              info_request.url_title)

        comment.reload
        expect(comment.attention_requested).to eq(true)
      end

      it "should not mark the parent request as having been reported" do
        expect(info_request.attention_requested).to eq(false)

        post :create, :request_id => info_request.url_title,
                      :comment_id => comment.id,
                      :reason => "my reason"
        expect(response)
          .to redirect_to show_request_path(:url_title =>
                                              info_request.url_title)

        info_request.reload
        expect(info_request.attention_requested).to eq(false)
        expect(info_request.described_state).to_not eq("attention_requested")
      end

      it "should send an email from the reporter to admins" do
        post :create, :request_id => info_request.url_title,
                      :comment_id => comment.id,
                      :reason => "my reason",
                      :message => "It's just not"
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.subject).to match(/requires admin/)
        expect(mail.header['Reply-To'].to_s).to include(user.email)
        expect(mail.body).to include(user.name)
        expect(mail.body)
          .to include("Reason: my reason\n\nIt's just not")
      end

      it "includes a note about the comment in the admin email" do
        post :create, :request_id => info_request.url_title,
                      :comment_id => comment.id,
                      :reason => "my reason",
                      :message => "It's just not"
        deliveries = ActionMailer::Base.deliveries
        mail = deliveries[0]
        expect(mail.body)
          .to include("The user wishes to draw attention to the comment: " \
                      "#{comment_url(comment)}")
      end

      it "sets the flash message" do
        expected = "This annotation has been reported for " \
                   "administrator attention"

        post :create, :request_id => info_request.url_title,
                      :comment_id => comment.id,
                      :reason => "my reason",
                      :message => "It's just not"

        expect(flash[:notice]).to eq(expected)
      end

    end
  end

  describe "GET #new" do
    let(:info_request){ FactoryGirl.create(:info_request) }
    let(:user){ FactoryGirl.create(:user) }

    context "not logged in" do
      it "should require the user to be logged in" do
        get :new, :request_id => info_request.url_title
        expect(response).not_to render_template("new")
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

      context "when passed a comment id" do
        render_views

        let(:comment) do
          FactoryGirl.create(:comment, :info_request => info_request)
        end

        it "ignores the comment id if it does not belong to the request" do
          new_comment = FactoryGirl.create(:comment)
          get :new, :request_id => info_request.url_title,
                    :comment_id => new_comment.id
          expect(response.body).to match(info_request.report_reasons.first)
        end

        it "alters the reasons dropdown if comment id is valid" do
          get :new, :request_id => info_request.url_title,
                    :comment_id => comment.id
          expect(response.body).
            to match(comment.report_reasons.first)
        end

        it "copies the comment id into a hidden form field" do
          get :new, :request_id => info_request.url_title,
                    :comment_id => comment.id
          expect(response.body).
            to have_selector("input#comment_id[value=\"#{comment.id}\"]",
                             :visible => false)
        end
      end

    end

  end

end
