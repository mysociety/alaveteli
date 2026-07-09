require 'spec_helper'

RSpec.describe UserProfile::NotificationPreferencesController do
  describe 'GET edit' do
    it 'sets the title' do
      get :edit
      expect(assigns[:title]).
        to eq("Change your notification preferences at #{ site_name }")
    end

    context 'without a logged in user' do
      it 'redirects to the home page' do
        sign_in nil
        get :edit
        expect(response).to redirect_to(frontpage_path)
      end
    end

    context 'with a logged in user' do
      let(:user) { FactoryBot.create(:user) }

      it 'assigns the currently logged in user' do
        sign_in user
        get :edit
        expect(assigns[:user]).to eq(user)
      end

      it 'is successful' do
        sign_in user
        get :edit
        expect(response).to be_successful
      end

      it 'renders the edit form' do
        sign_in user
        get :edit
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'PUT update' do
    it 'sets the title' do
      put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
      expect(assigns[:title]).
        to eq("Change your notification preferences at #{ site_name }")
    end

    context 'without a logged in user' do
      it 'redirects to the home page' do
        sign_in nil
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        expect(response).to redirect_to(frontpage_path)
      end
    end

    context 'with a banned user' do
      let(:banned_user) { FactoryBot.create(:user, ban_text: 'banned') }

      before :each do
        sign_in banned_user
      end

      it 'displays an error' do
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        expect(flash[:error]).to eq('Suspended users cannot edit their profile')
      end

      it 'redirects to edit' do
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        expect(response).to redirect_to(edit_profile_notification_preferences_path)
      end
    end

    context 'with valid attributes' do
      let(:user) { FactoryBot.create(:user) }

      before :each do
        sign_in user
      end

      it 'assigns the currently logged in user' do
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        expect(assigns[:user]).to eq(user)
      end

      it 'updates the notification preferences' do
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        user.reload
        expect(user.send_daily_summary).to be(false)
        expect(user.send_immediate_request_alerts).to be(false)
      end

      it 'sets a success flash message' do
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        expect(flash[:notice]).to eq("Your notification preferences have been updated.")
      end

      it 'redirects back to edit' do
        put :update, params: { user: { send_daily_summary: 'false', send_immediate_request_alerts: 'false' } }
        expect(response).to redirect_to(edit_profile_notification_preferences_path)
      end
    end

    context 'with invalid parameters' do
      let(:user) { FactoryBot.create(:user) }

      before :each do
        sign_in user
      end

      it 'redirects to the edit page' do
        put :update
        expect(response).to redirect_to(edit_profile_notification_preferences_path)
      end
    end
  end
end
