require 'spec_helper'

RSpec.describe AdminAnnouncementsController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET index' do
    before { get :index }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns the announcements' do
      expect(assigns[:announcements]).to all(be_a(Announcement))
    end
  end

  describe 'GET new' do
    before { get :new }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns a default style announcement' do
      expect(assigns[:announcement]).to be_default_style
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        announcement: {
          visibility: 'everyone',
          style: 'yellow',
          title: 'Hello',
          rich_body: 'New body'
        }
      }
    end

    context 'with valid params' do
      before { post :create, params: params }

      it 'creates the announcement' do
        announcement = assigns[:announcement]
        expect(announcement).to be_persisted
        expect(announcement).to be_yellow_style
        expect(announcement.rich_body.to_plain_text).to eq('New body')
      end

      it 'redirects to the index' do
        expect(response).to redirect_to(admin_announcements_path)
      end
    end

    context 'without a body' do
      before do
        params[:announcement][:rich_body] = ''
        post :create, params: params
      end

      it 're-renders the form' do
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #update' do
    let(:announcement) { FactoryBot.create(:announcement) }

    before do
      patch :update, params: {
        id: announcement.id,
        announcement: { style: 'green' }
      }
    end

    it 'updates the style' do
      expect(announcement.reload).to be_green_style
    end
  end
end
