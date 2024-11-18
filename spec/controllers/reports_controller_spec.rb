require 'spec_helper'

RSpec.describe ReportsController do
  describe 'POST #create' do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:user) { FactoryBot.create(:user) }

    context "when reporting a request when not logged in" do
      it "should only allow logged-in users to report requests" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }
        expect(flash[:notice]).to match(/You need to be logged in/)
        expect(response).
          to redirect_to show_request_path(info_request.url_title)
      end
    end

    context "when reporting a request (logged in)" do
      before do
        sign_in user
      end

      it "finds the expected request" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }

        expect(assigns(:info_request)).to eq(info_request)
      end

      it "sets reportable to the request" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }

        expect(assigns(:reportable)).to eq(info_request)
      end

      it "sets report_reasons to the request report reasons" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }

        expect(assigns(:report_reasons)).to eq(info_request.report_reasons)
      end

      it 'logs an event' do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: 'my reason'
        }
        last_event = info_request.reload.last_event
        expect(last_event.event_type).to eq('report_request')
        expect(last_event.params).to eq(
          request: { gid: info_request.to_global_id.to_s },
          editor: { gid: user.to_global_id.to_s },
          reason: 'my reason',
          message: '',
          old_attention_requested: false,
          attention_requested: true
        )
      end

      it 'ignores an empty comment_id param' do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: '',
          reason: "my reason"
        }
        expect(assigns[:comment]).to be_nil
      end

      it "should 404 for non-existent requests" do
        expect {
          post :create, params: { request_url_title: "hjksfdhjk_louytu_qqxxx" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should 404 for embargoed requests' do
        info_request = FactoryBot.create(:embargoed_request)
        expect {
          post :create, params: { request_url_title: info_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should mark a request as having been reported" do
        expect(info_request.attention_requested).to eq(false)

        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }
        expect(response).
          to redirect_to show_request_path(info_request.url_title)

        info_request.reload
        expect(info_request.attention_requested).to eq(true)
        expect(info_request.described_state).to eq("attention_requested")
      end

      it "sets the flash message when the request gets successfully reported" do
        expected = "This request has been reported for administrator attention"

        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason",
          message: "It's just not"
        }

        expect(flash[:notice]).to eq(expected)
      end

      it "should not allow a request to be reported twice" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }
        expect(response).
          to redirect_to show_request_url(info_request.url_title)

        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason"
        }
        expect(response).
          to redirect_to show_request_url(info_request.url_title)
        expect(flash[:notice]).to match(/has already been reported/)
      end

      it "should send an email from the reporter to admins" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: "my reason",
          message: "It's just not"
        }
        expect(deliveries.size).to eq(1)
        mail = deliveries.first
        expect(mail.subject).to match(/attention_requested/)
        expect(mail.header['Reply-To'].to_s).to include(user.email)
        expect(mail.body).to include(user.name)
        expect(mail.body)
          .to include("Reason: my reason\n\nIt's just not")
      end

      it "should force the user to pick a reason" do
        post :create, params: {
          request_url_title: info_request.url_title,
          reason: ""
        }
        expect(response).to render_template("new")
        expect(flash[:error]).to eq("Please choose a reason")
      end
    end

    context "when reporting a comment (logged in)" do
      before do
        sign_in user
      end

      let(:comment) do
        FactoryBot.create(:comment, info_request: info_request,
                                    attention_requested: false)
      end

      it "finds the expected request" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        expect(assigns(:info_request)).to eq(info_request)
      end

      it "finds the expected comment" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        expect(assigns(:comment)).to eq(comment)
      end

      it "sets reportable to the comment" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        expect(assigns(:reportable)).to eq(comment)
      end

      it "sets report_reasons to the comment report reasons" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        expect(assigns(:report_reasons)).to eq(comment.report_reasons)
      end

      it "returns a 404 if the comment does not belong to the request" do
        new_comment = FactoryBot.create(:comment)
        expect {
          post :create, params: {
            request_url_title: info_request.url_title,
            comment_id: new_comment.id,
            reason: "my reason"
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "marks the comment as having been reported" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        comment.reload
        expect(comment.attention_requested).to eq(true)
      end

      it "does not mark the parent request as having been reported" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        info_request.reload
        expect(info_request.attention_requested).to eq(false)
        expect(info_request.described_state).to_not eq("attention_requested")
      end

      it "sends an email alerting admins to the report" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason",
          message: "It's just not"
        }

        expect(deliveries.size).to eq(1)
        mail = deliveries.first

        expect(mail.subject).to match(/requires admin/)
        expect(mail.header['Reply-To'].to_s).to include(user.email)
        expect(mail.body).to include(user.name)

        expect(mail.body)
          .to include("Reason: my reason\n\nIt's just not")

        expect(mail.body)
          .to include("The user wishes to draw attention to the comment: " \
                      "#{comment_url(comment)} "\
                      "\nadmin: #{edit_admin_comment_url(comment)}")
      end

      it "informs the user the comment has been reported" do
        expected = "This annotation has been reported for " \
                   "administrator attention"

        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason",
          message: "It's just not"
        }

        expect(flash[:notice]).to eq(expected)
      end

      it "redirects to the parent info_request page" do
        post :create, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason",
          message: "It's just not"
        }

        expect(response).
          to redirect_to show_request_path(info_request.url_title)
      end
    end
  end

  describe "GET #new" do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:user) { FactoryBot.create(:user) }

    context "not logged in" do
      it "should require the user to be logged in" do
        get :new, params: { request_url_title: info_request.url_title }
        expect(response).
          to redirect_to(signin_path(token: PostRedirect.last.token))
      end
    end

    context "when reporting a request (logged in)" do
      before :each do
        sign_in user
      end

      it "finds the expected request" do
        get :new, params: { request_url_title: info_request.url_title }
        expect(assigns(:info_request)).to eq(info_request)
      end

      it "sets reportable to the request" do
        get :new, params: { request_url_title: info_request.url_title }
        expect(assigns(:reportable)).to eq(info_request)
      end

      it "sets report_reasons to the request report reasons" do
        get :new, params: { request_url_title: info_request.url_title }
        expect(assigns(:report_reasons)).to eq(info_request.report_reasons)
      end

      it "sets the page title" do
        get :new, params: { request_url_title: info_request.url_title }

        expect(assigns(:title)).
          to eq("Report request: #{ info_request.title }")
      end

      it "should show the form" do
        get :new, params: { request_url_title: info_request.url_title }
        expect(response).to render_template("new")
      end

      it "should 404 for non-existent requests" do
        expect {
          get :new, params: { request_url_title: "hjksfdhjk_louytu_qqxxx" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should 404 for embargoed requests' do
        info_request = FactoryBot.create(:embargoed_request)
        expect {
          get :new, params: { request_url_title: info_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when reporting a comment (logged in)" do
      render_views

      before :each do
        sign_in user
      end

      let(:comment) do
        FactoryBot.create(:comment, info_request: info_request,
                                    attention_requested: false)
      end

      it "finds the expected request" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id
        }
        expect(assigns(:info_request)).to eq(info_request)
      end

      it "finds the expected comment" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id,
          reason: "my reason"
        }

        expect(assigns(:comment)).to eq(comment)
      end

      it "sets reportable to the comment" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id
        }

        expect(assigns(:reportable)).to eq(comment)
      end

      it "sets report_reasons to the comment report reasons" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id
        }

        expect(assigns(:report_reasons)).to eq(comment.report_reasons)
      end

      it "sets the page title" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id
        }

        expect(assigns(:title)).
          to eq("Report annotation on request: #{ info_request.title }")
      end

      it "returns a 404 if the comment does not belong to the request" do
        new_comment = FactoryBot.create(:comment)
        expect {
          get :new, params: {
            request_url_title: info_request.url_title,
            comment_id: new_comment.id
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should show the form" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id
        }
        expect(response).to render_template("new")
      end

      it "copies the comment id into a hidden form field" do
        get :new, params: {
          request_url_title: info_request.url_title,
          comment_id: comment.id
        }
        expect(response.body).
          to have_selector("input#comment_id[value=\"#{comment.id}\"]",
                           visible: false)
      end

      it "should 404 for non-existent requests" do
        expect {
          get :new, params: {
            request_url_title: "hjksfdhjk_louytu_qqxxx",
            comment_id: comment.id
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should 404 for embargoed requests' do
        info_request = FactoryBot.create(:embargoed_request)
        expect {
          get :new, params: {
            request_url_title: info_request.url_title,
            comment_id: comment.id
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
