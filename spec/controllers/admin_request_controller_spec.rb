# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRequestController, "when administering requests" do
  render_views
  before { basic_auth_login @request }

  before(:each) do
    load_raw_emails_data
  end

  it "shows the index/list page" do
    get :index
  end

  it "shows a public body" do
    get :show, :id => info_requests(:fancy_dog_request)
  end

  it 'shows an external public body with no username' do
    get :show, :id => info_requests(:anonymous_external_request)
    expect(response).to be_success
  end

  it "edits a public body" do
    get :edit, :id => info_requests(:fancy_dog_request)
  end

  it "saves edits to a request" do
    expect(info_requests(:fancy_dog_request).title).to eq("Why do you have & such a fancy dog?")
    post :update, { :id => info_requests(:fancy_dog_request),
                    :info_request => { :title => "Renamed",
                                       :prominence => "normal",
                                       :described_state => "waiting_response",
                                       :awaiting_description => false,
                                       :allow_new_responses_from => 'anybody',
                                       :handle_rejected_responses => 'bounce' } }
    expect(request.flash[:notice]).to include('successful')
    ir = InfoRequest.find(info_requests(:fancy_dog_request).id)
    expect(ir.title).to eq("Renamed")
  end

  it 'expires the request cache when saving edits to it' do
    info_request = FactoryGirl.create(:info_request)
    allow(InfoRequest).to receive(:find).with(info_request.id.to_s).and_return(info_request)
    expect(info_request).to receive(:expire)
    post :update, { :id => info_request,
                    :info_request => { :title => "Renamed",
                                       :prominence => "normal",
                                       :described_state => "waiting_response",
                                       :awaiting_description => false,
                                       :allow_new_responses_from => 'anybody',
                                       :handle_rejected_responses => 'bounce' } }
  end

  describe "when moving a request to another authority" do
    let(:body1) { FactoryGirl.create(:public_body) }
    let(:body2) { FactoryGirl.create(:public_body) }
    let(:request) { FactoryGirl.create(:info_request, :public_body => body1) }

    before do
      post :move, { :id => request.id,
                    :public_body_url_name => body2.url_name,
                    :commit => "Move request to authority" }
    end

    it "should assign the request to the new authority" do
      body2.reload
      expect(body2.info_requests.first).to eq(request)
    end

    it "should unassign the request from the previous authority" do
      body1.reload
      expect(body1.info_requests).to eq([])
    end

    it "should increment the new authority's info_requests_count" do
      body2.reload
      expect(body2.info_requests_count).to eq(1)
    end

    it "should decrement the previous authority's info_requests_count" do
      body1.reload
      expect(body1.info_requests_count).to eq(0)
    end
  end

  describe "when moving a request to another user" do
    let(:user1) { FactoryGirl.create(:user) }
    let(:user2) { FactoryGirl.create(:user) }
    let(:request) { FactoryGirl.create(:info_request, :user => user1) }

    before do
      post :move, { :id => request.id,
                    :user_url_name => user2.url_name,
                    :commit => "Move request to user" }
    end

    it "should assign the request to the new user" do
      user2.reload
      expect(user2.info_requests.first).to eq(request)
    end

    it "should unassign the request from the previous user" do
      user1.reload
      expect(user1.info_requests).to eq([])
    end

    it "should increment the new user's info_requests_count" do
      user2.reload
      expect(user2.info_requests_count).to eq(1)
    end

    it "should decrement the previous user's info_requests_count" do
      user1.reload
      expect(user1.info_requests_count).to eq(0)
    end
  end


  describe 'when fully destroying a request' do

    it 'calls destroy on the info_request object' do
      info_request = FactoryGirl.create(:info_request)
      allow(InfoRequest).to receive(:find).with(info_request.id.to_s).and_return(info_request)
      expect(info_request).to receive(:destroy)
      get :destroy, { :id => info_request.id }
    end

    it 'uses a different flash message to avoid trying to fetch a non existent user record' do
      info_request = info_requests(:external_request)
      post :destroy, { :id => info_request.id }
      expect(request.flash[:notice]).to include('external')
    end

    it 'redirects after destroying a request with incoming_messages' do
      info_request = FactoryGirl.create(:info_request)
      incoming_message = FactoryGirl.create(:incoming_message_with_html_attachment,
                                            :info_request => info_request)
      delete :destroy, { :id => info_request.id }

      expect(response).to redirect_to(admin_requests_url)
    end

  end

end

describe AdminRequestController, "when administering the holding pen" do
  render_views
  before(:each) do
    basic_auth_login @request
    load_raw_emails_data
  end

  it "shows a suitable default 'your email has been hidden' message" do
    ir = info_requests(:fancy_dog_request)
    get :show, :id => ir.id
    expect(assigns[:request_hidden_user_explanation]).to include(ir.user.name)
    expect(assigns[:request_hidden_user_explanation]).to include("vexatious")
    get :show, :id => ir.id, :reason => "not_foi"
    expect(assigns[:request_hidden_user_explanation]).not_to include("vexatious")
    expect(assigns[:request_hidden_user_explanation]).to include("not a valid FOI")
  end

  describe 'when hiding requests' do

    it "hides requests and sends a notification email that it has done so" do
      ir = info_requests(:fancy_dog_request)
      post :hide, :id => ir.id, :explanation => "Foo", :reason => "vexatious"
      ir.reload
      expect(ir.prominence).to eq("requester_only")
      expect(ir.described_state).to eq("vexatious")
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/Foo/)
    end

    it 'expires the file cache for the request' do
      info_request = FactoryGirl.create(:info_request)
      allow(InfoRequest).to receive(:find).with(info_request.id.to_s).and_return(info_request)
      expect(info_request).to receive(:expire)
      post :hide, :id => info_request.id, :explanation => "Foo", :reason => "vexatious"
    end

    describe 'when hiding an external request' do

      before do
        @info_request = mock_model(InfoRequest, :prominence= => nil,
                                   :log_event => nil,
                                   :set_described_state => nil,
                                   :save! => nil,
                                   :user => nil,
                                   :user_name => 'External User',
                                   :is_external? => true)
        allow(@info_request).to receive(:expire)

        allow(InfoRequest).to receive(:find).with(@info_request.id.to_s).and_return(@info_request)
        @default_params = { :id => @info_request.id,
                            :explanation => 'Foo',
                            :reason => 'vexatious' }
      end

      def make_request(params=@default_params)
        post :hide, params
      end

      it 'should redirect the the admin page for the request' do
        make_request
        expect(response).to redirect_to(:controller => 'admin_request',
                                    :action => 'show',
                                    :id => @info_request.id)
      end

      it 'should set the request prominence to "requester_only"' do
        expect(@info_request).to receive(:prominence=).with('requester_only')
        expect(@info_request).to receive(:save!)
        make_request
      end

      it 'should not send a notification email' do
        expect(ContactMailer).not_to receive(:from_admin_message)
        make_request
      end

      it 'should add a notice to the flash saying that the request has been hidden' do
        make_request
        expect(request.flash[:notice]).to eq("This external request has been hidden")
      end

      it 'should expire the file cache for the request' do
        expect(@info_request).to receive(:expire)
        make_request
      end
    end

  end

end
