require 'spec_helper'

RSpec.describe AdminRequestController, "when administering requests" do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  describe 'GET #index' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before { sign_in(admin_user) }

    it "is successful" do
      get :index
      expect(response).to be_successful
    end

    it 'assigns all info requests to the view' do
      get :index
      expect(assigns[:info_requests]).to match_array(InfoRequest.all)
    end

    it 'does not include embargoed requests if the current user is
        not a pro admin user' do
      info_request.create_embargo
      get :index
      expect(assigns[:info_requests].include?(info_request)).to be false
    end


    context 'when pro is enabled' do

      it 'does not include embargoed requests if the current user is
          not a pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          info_request.create_embargo
          get :index
          expect(assigns[:info_requests].include?(info_request)).to be false
        end
      end

      it 'includes embargoed requests if the current user
          is a pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          info_request.create_embargo
          sign_in pro_admin_user
          get :index
          expect(assigns[:info_requests].include?(info_request)).to be true
        end
      end
    end

    context 'when passed a query' do
      let!(:dog_request) { FactoryBot.create(:info_request,
                                            :title => 'A dog request') }
      let!(:cat_request) { FactoryBot.create(:info_request,
                                            :title => 'A cat request') }

      it 'assigns info requests with titles matching the query to the view
          case insensitively' do
        get :index, params: { :query => 'Cat' }
        expect(assigns[:info_requests].include?(dog_request)).to be false
        expect(assigns[:info_requests].include?(cat_request)).to be true
      end

      it 'does not include embargoed requests if the current user is an
          admin user' do
        cat_request.create_embargo
        get :index, params: { :query => 'cat' }
        expect(assigns[:info_requests].include?(cat_request)).to be false
      end

      context 'when pro is enabled' do
        it 'does not include embargoed requests if the current user is an
            admin user' do
          with_feature_enabled(:alaveteli_pro) do
            cat_request.create_embargo
            get :index, params: { :query => 'cat' }
            expect(assigns[:info_requests].include?(cat_request)).to be false
          end
        end

        it 'includes embargoed requests if the current user
            is a pro admin user' do
          with_feature_enabled(:alaveteli_pro) do
            cat_request.create_embargo
            sign_in pro_admin_user
            get :index, params: { :query => 'cat' }
            expect(assigns[:info_requests].include?(cat_request)).to be true
          end
        end
      end

    end

  end

  describe 'GET #show' do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:external_request) { FactoryBot.create(:external_request) }

    before { sign_in(admin_user) }

    render_views

    it "is successful" do
      get :show, params: { :id => info_request }
      expect(response).to be_successful
    end

    it 'shows an external info request with no username' do
      get :show, params: { :id => external_request }
      expect(response).to be_successful
    end

    context 'if the request is embargoed' do

      before do
        info_request.create_embargo
      end

      it 'raises ActiveRecord::RecordNotFound for an admin user' do
        expect {
          sign_in admin_user
          get :show, params: { :id => info_request.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end

      context 'with pro enabled' do

        it 'raises ActiveRecord::RecordNotFound for an admin user' do
          with_feature_enabled(:alaveteli_pro) do
            expect {
              sign_in admin_user
              get :show, params: { :id => info_request.id }
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        it 'is successful for a pro admin user' do
          with_feature_enabled(:alaveteli_pro) do
            sign_in pro_admin_user
            get :show, params: { :id => info_request.id }
            expect(response).to be_successful
          end
        end
      end

    end

  end

  describe 'GET #edit' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before { sign_in(admin_user) }

    it "is successful" do
      get :edit, params: { :id => info_request }
      expect(response).to be_successful
    end

  end

  describe 'PUT #update' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before { sign_in(admin_user) }

    it "saves edits to a request" do
      post :update, params: {
                      :id => info_request,
                      :info_request => {
                        :title => "Renamed",
                        :prominence => "normal",
                        :described_state => "waiting_response",
                        :awaiting_description => false,
                        :allow_new_responses_from => 'anybody',
                        :handle_rejected_responses => 'bounce'
                      }
                    }
      expect(request.flash[:notice]).to include('successful')
      info_request.reload
      expect(info_request.title).to eq("Renamed")
    end

    it 'expires the request cache when saving edits to it' do
      allow(InfoRequest).to receive(:find).
        with(info_request.id).and_return(info_request)
      expect(info_request).to receive(:expire)
      post :update, params: {
                      :id => info_request.id,
                      :info_request => {
                        :title => "Renamed",
                        :prominence => "normal",
                        :described_state => "waiting_response",
                        :awaiting_description => false,
                        :allow_new_responses_from => 'anybody',
                        :handle_rejected_responses => 'bounce'
                      }
                    }
    end

  end

  describe 'DELETE #destroy' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before { sign_in(admin_user) }

    it 'calls destroy on the info_request object' do
      allow(InfoRequest).to receive(:find).
        with(info_request.id).and_return(info_request)
      expect(info_request).to receive(:destroy)
      delete :destroy, params: { :id => info_request.id }
    end

    it 'uses a different flash message to avoid trying to fetch a non existent user record' do
      info_request = info_requests(:external_request)
      delete :destroy, params: { :id => info_request.id }
      expect(request.flash[:notice]).to include('external')
    end

    it 'redirects after destroying a request with incoming_messages' do
      incoming_message = FactoryBot.create(:incoming_message_with_html_attachment,
                                           :info_request => info_request)
      delete :destroy, params: { :id => info_request.id }

      expect(response).to redirect_to(admin_requests_url)
    end

  end

  describe 'POST #hide' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before { sign_in(admin_user) }

    it "hides requests and sends a notification email that it has done so" do
      post :hide, params: {
                    :id => info_request.id,
                    :explanation => "Foo",
                    :reason => "vexatious"
                  }
      info_request.reload
      expect(info_request.prominence).to eq("requester_only")
      expect(info_request.described_state).to eq("vexatious")
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/Foo/)
    end

    it 'expires the file cache for the request' do
      allow(InfoRequest).to receive(:find).
        with(info_request.id).and_return(info_request)
      expect(info_request).to receive(:expire)
      post :hide, params: {
                    :id => info_request.id,
                    :explanation => "Foo",
                    :reason => "vexatious"
                  }
    end

    context 'when hiding an external request' do

      before do
        @info_request = FactoryBot.create(:external_request)
        allow(InfoRequest).to receive(:find).with(@info_request.id).
          and_return(@info_request)

        @default_params = { :id => @info_request.id,
                            :explanation => 'Foo',
                            :reason => 'vexatious' }
      end

      def make_request(params=@default_params)
        post :hide, params: params
      end

      it 'should redirect the the admin page for the request' do
        make_request
        expect(response).to redirect_to(:controller => 'admin_request',
                                        :action => 'show',
                                        :id => @info_request.id)
      end

      it 'should set the request prominence to "requester_only"' do
        expect { make_request }.to change(@info_request, :prominence).
          to('requester_only')
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
