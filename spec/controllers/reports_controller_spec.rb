# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ReportsController, "when reporting a request when not logged in" do
  it "should only allow logged-in users to report requests" do
    post :create, :request_id => info_requests(:badger_request).url_title, :reason => "my reason"

    expect(flash[:notice]).to match(/You need to be logged in/)
    expect(response).to redirect_to show_request_path(:url_title => info_requests(:badger_request).url_title)
  end
end

describe ReportsController, "when reporting a request (logged in)" do
  render_views

  before do
    @user = users(:robin_user)
    session[:user_id] = @user.id
  end

  it "should 404 for non-existent requests" do
    expect {
      post :create, :request_id => "hjksfdhjk_louytu_qqxxx"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should mark a request as having been reported" do
    ir = info_requests(:badger_request)
    title = ir.url_title
    expect(ir.attention_requested).to eq(false)

    post :create, :request_id => title, :reason => "my reason"
    expect(response).to redirect_to show_request_path(:url_title => title)

    ir.reload
    expect(ir.attention_requested).to eq(true)
    expect(ir.described_state).to eq("attention_requested")
  end

  it "should pass on the reason and message" do
    info_request = mock_model(InfoRequest, :url_title => "foo", :attention_requested= => nil, :save! => nil)
    expect(InfoRequest).to receive(:find_by_url_title!).with("foo").and_return(info_request)
    expect(info_request).to receive(:report!).with("Not valid request", "It's just not", @user)
    post :create, :request_id => "foo", :reason => "Not valid request", :message => "It's just not"
  end

  it "should not allow a request to be reported twice" do
    title = info_requests(:badger_request).url_title

    post :create, :request_id => title, :reason => "my reason"
    expect(response).to redirect_to show_request_url(:url_title => title)

    post :create, :request_id => title, :reason => "my reason"
    expect(response).to redirect_to show_request_url(:url_title => title)
    expect(flash[:notice]).to match(/has already been reported/)
  end

  it "should send an email from the reporter to admins" do
    ir = info_requests(:badger_request)
    title = ir.url_title
    post :create, :request_id => title, :reason => "my reason"
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.subject).to match(/attention_requested/)
    expect(mail.from).to include(@user.email)
    expect(mail.body).to include(@user.name)
  end

  it "should force the user to pick a reason" do
    info_request = mock_model(InfoRequest, :report! => nil, :url_title => "foo",
                              :report_reasons => ["Not FOIish enough"])
    expect(InfoRequest).to receive(:find_by_url_title!).with("foo").and_return(info_request)

    post :create, :request_id => "foo", :reason => ""
    expect(response).to render_template("new")
    expect(flash[:error]).to eq("Please choose a reason")
  end
end

describe ReportsController, "#new_report_request" do
  let(:info_request) { mock_model(InfoRequest, :url_title => "foo") }
  before :each do
    expect(InfoRequest).to receive(:find_by_url_title!).with("foo").and_return(info_request)
  end

  context "not logged in" do
    it "should require the user to be logged in" do
      get :new, :request_id => "foo"
      expect(response).not_to render_template("new")
    end
  end

  context "logged in" do
    before :each do
      session[:user_id] = users(:bob_smith_user).id
    end
    it "should show the form" do
      get :new, :request_id => "foo"
      expect(response).to render_template("new")
    end
  end
end
