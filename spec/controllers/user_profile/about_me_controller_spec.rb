# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe UserProfile::AboutMeController do

  describe 'GET edit' do

    it 'sets the title' do
      get :edit
      site_name = AlaveteliConfiguration.site_name
      expect(assigns[:title]).
        to eq("Change the text about you on your profile at #{ site_name }")
    end

    context 'without a logged in user' do

      it 'redirects to the home page' do
        session[:user_id] = nil
        get :edit
        expect(response).to redirect_to(frontpage_path)
      end

    end

    context 'with a logged in user' do

      let(:user) { FactoryGirl.create(:user) }

      it 'assigns the currently logged in user' do
        session[:user_id] = user.id
        get :edit
        expect(assigns[:user]).to eq(user)
      end

      it 'is successful' do
        session[:user_id] = user.id
        get :edit
        expect(response).to be_success
      end

      it 'renders the edit form' do
        session[:user_id] = user.id
        get :edit
        expect(response).to render_template(:edit)
      end

    end

  end

  describe 'PUT update' do

    it 'sets the title' do
      put :update, :user => { :about_me => 'My bio' }
      site_name = AlaveteliConfiguration.site_name
      expect(assigns[:title]).
        to eq("Change the text about you on your profile at #{ site_name }")
    end

    context 'without a logged in user' do

      it 'redirects to the sign in page' do
        session[:user_id] = nil
        put :update, :user => { :about_me => 'My bio' }
        expect(response).to redirect_to(frontpage_path)
      end

    end

    context 'with a banned user' do

      let(:banned_user) { FactoryGirl.create(:user, :ban_text => 'banned') }

      before :each do
        session[:user_id] = banned_user.id
      end

      it 'displays an error' do
        put :update, :user => { :about_me => 'My bio' }
        expect(flash[:error]).to eq('Banned users cannot edit their profile')
      end

      it 'redirects to edit' do
        put :update, :user => { :about_me => 'My bio' }
        expect(response).to redirect_to(edit_profile_about_me_path)
      end

    end

    context 'with valid attributes' do

      let(:user) { FactoryGirl.create(:user) }

      before :each do
        session[:user_id] = user.id
      end

      it 'assigns the currently logged in user' do
        put :update, :user => { :about_me => 'My bio' }
        expect(assigns[:user]).to eq(user)
      end

      it 'updates the user about_me' do
        put :update, :user => { :about_me => 'My bio' }
        expect(user.reload.about_me).to eq('My bio')
      end

      context 'if the user has a profile photo' do

        it 'sets a success message' do
          user.create_profile_photo!(:data => load_file_fixture('parrot.png'))
          put :update, :user => { :about_me => 'My bio' }
          msg = 'You have now changed the text about you on your profile.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'redirects to the user page' do
          user.create_profile_photo!(:data => load_file_fixture('parrot.png'))
          put :update, :user => { :about_me => 'My bio' }
          expect(response).
            to redirect_to(show_user_path(:url_name => user.url_name))
        end

      end

      context 'if the user does not have a profile photo' do

        it 'sets a message suggesting they add one' do
          put :update, :user => { :about_me => 'My bio' }
          msg = "<p>Thanks for changing the text about you on your " \
                "profile.</p><p><strong>Next...</strong> You can " \
                "upload a profile photograph too.</p>"
          expect(flash[:notice]).to eq(msg)
        end

        it 'redirects to the set profile photo page' do
          put :update, :user => { :about_me => 'My bio' }
          expect(response).to redirect_to(set_profile_photo_path)
        end

      end

    end

    context 'with invalid attributes' do

      let(:user) { FactoryGirl.create(:user, :about_me => 'My bio') }
      let(:invalid_text) { 'x' * 1000 }

      before :each do
        session[:user_id] = user.id
      end

      it 'assigns the currently logged in user' do
        put :update, :user => { :about_me => invalid_text }
        expect(assigns[:user]).to eq(user)
      end

      it 'does not update the user about_me' do
        put :update, :user => { :about_me => invalid_text }
        expect(user.reload.about_me).to eq('My bio')
      end

      it 'renders the edit form' do
        put :update, :user => { :about_me => invalid_text }
        expect(response).to render_template(:edit)
      end

    end

    context 'with extra attributes' do

      let(:user) { FactoryGirl.create(:user) }

      before :each do
        session[:user_id] = user.id
      end

      it 'ignores non-whitelisted attributes' do
        put :update, :user => { :about_me => 'My bio', :admin_level => 'super' }
        expect(user.reload.admin_level).to eq('none')
      end

      it 'sets whitelisted attributes' do
        put :update, :user => { :about_me => 'My bio', :admin_level => 'super' }
        expect(user.reload.about_me).to eq('My bio')
      end

    end


  end

end
