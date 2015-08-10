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
    info_request = info_requests(:fancy_dog_request)
    expect(@controller).to receive(:expire_for_request).with(info_request)
    post :update, { :id => info_request,
                    :info_request => { :title => "Renamed",
                                       :prominence => "normal",
                                       :described_state => "waiting_response",
                                       :awaiting_description => false,
                                       :allow_new_responses_from => 'anybody',
                                       :handle_rejected_responses => 'bounce' } }

  end

  describe 'when fully destroying a request' do

    it 'expires the file cache for that request' do
      info_request = info_requests(:badger_request)
      expect(@controller).to receive(:expire_for_request).with(info_request)
      get :destroy, { :id => info_request }
    end

    it 'uses a different flash message to avoid trying to fetch a non existent user record' do
      info_request = info_requests(:external_request)
      post :destroy, { :id => info_request.id }
      expect(request.flash[:notice]).to include('external')
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
      ir = info_requests(:fancy_dog_request)
      expect(@controller).to receive(:expire_for_request).with(ir)
      post :hide, :id => ir.id, :explanation => "Foo", :reason => "vexatious"
    end

    describe 'when hiding an external request' do

      before do
        allow(@controller).to receive(:expire_for_request)
        @info_request = mock_model(InfoRequest, :prominence= => nil,
                                   :log_event => nil,
                                   :set_described_state => nil,
                                   :save! => nil,
                                   :user => nil,
                                   :user_name => 'External User',
                                   :is_external? => true)
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
        expect(@controller).to receive(:expire_for_request)
        make_request
      end
    end

  end

end
