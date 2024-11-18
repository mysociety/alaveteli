require 'spec_helper'

RSpec.describe UserProfile::AboutMeController do
  describe 'GET edit' do
    it 'sets the title' do
      get :edit
      expect(assigns[:title]).
        to eq("Change the text about you on your profile at #{ site_name }")
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
      put :update, params: { user: { about_me: 'My bio' } }
      expect(assigns[:title]).
        to eq("Change the text about you on your profile at #{ site_name }")
    end

    context 'without a logged in user' do
      it 'redirects to the sign in page' do
        sign_in nil
        put :update, params: { user: { about_me: 'My bio' } }
        expect(response).to redirect_to(frontpage_path)
      end
    end

    context 'with a banned user' do
      let(:banned_user) { FactoryBot.create(:user, ban_text: 'banned') }

      before :each do
        sign_in banned_user
      end

      it 'displays an error' do
        put :update, params: { user: { about_me: 'My bio' } }
        expect(flash[:error]).to eq('Suspended users cannot edit their profile')
      end

      it 'redirects to edit' do
        put :update, params: { user: { about_me: 'My bio' } }
        expect(response).to redirect_to(edit_profile_about_me_path)
      end
    end

    context 'with valid attributes' do
      let(:user) { FactoryBot.create(:user) }

      before :each do
        sign_in user
      end

      it 'assigns the currently logged in user' do
        put :update, params: { user: { about_me: 'My bio' } }
        expect(assigns[:user]).to eq(user)
      end

      it 'updates the user about_me' do
        put :update, params: { user: { about_me: 'My bio' } }
        expect(user.reload.about_me).to eq('My bio')
      end

      context 'if the user has a profile photo' do
        it 'sets a success message' do
          user.create_profile_photo!(data: load_file_fixture('parrot.png'))
          put :update, params: { user: { about_me: 'My bio' } }
          msg = 'You have now changed the text about you on your profile.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'redirects to the user page' do
          user.create_profile_photo!(data: load_file_fixture('parrot.png'))
          put :update, params: { user: { about_me: 'My bio' } }
          expect(response).
            to redirect_to(show_user_path(url_name: user.url_name))
        end
      end

      context 'if the user does not have a profile photo' do
        it 'sets a message suggesting they add one' do
          put :update, params: { user: { about_me: 'My bio' } }
          expect(flash[:notice][:partial]).to eq("update_profile_text")
        end

        it 'redirects to the set profile photo page' do
          put :update, params: { user: { about_me: 'My bio' } }
          expect(response).to redirect_to(set_profile_photo_path)
        end
      end
    end

    context 'with invalid attributes' do
      let(:user) { FactoryBot.create(:user, about_me: 'My bio') }
      let(:invalid_text) { 'x' * 1000 }

      before :each do
        sign_in user
      end

      it 'assigns the currently logged in user' do
        put :update, params: { user: { about_me: invalid_text } }
        expect(assigns[:user]).to eq(user)
      end

      it 'does not update the user about_me' do
        put :update, params: { user: { about_me: invalid_text } }
        expect(user.reload.about_me).to eq('My bio')
      end

      it 'renders the edit form' do
        put :update, params: { user: { about_me: invalid_text } }
        expect(response).to render_template(:edit)
      end
    end

    context 'with invalid parameters' do
      let(:user) { FactoryBot.create(:user, about_me: 'My bio') }

      before :each do
        sign_in user
      end

      it 'assigns the currently logged in user' do
        put :update, params: { about_me: 'Updated text' }
        expect(assigns[:user]).to eq(user)
      end

      it 'does not update the user about_me' do
        put :update, params: { about_me: 'Updated text' }
        expect(user.reload.about_me).to eq('My bio')
      end

      it 'redirects to the user page' do
        put :update, params: { about_me: 'Updated text' }
        expect(response).
          to redirect_to(show_user_path(url_name: user.url_name))
      end
    end

    context 'with extra attributes' do
      let(:user) { FactoryBot.create(:user) }

      before :each do
        sign_in user
      end

      it 'ignores non-whitelisted attributes' do
        put :update, params: {
                       user: {
                         about_me: 'My bio',
                         role_ids: [ Role.admin_role.id ]
                       }
                     }
        expect(user.reload.roles).to eq([])
      end

      it 'sets whitelisted attributes' do
        user = FactoryBot.create(:user, name: '1234567')
        sign_in user
        put :update, params: {
                       user: {
                         about_me: 'My bio',
                         role_ids: [ Role.admin_role.id ]
                       }
                     }
        expect(user.reload.about_me).to eq('My bio')
      end
    end

    context 'with spam attributes and a non-whitelisted user' do
      let(:user) do
        FactoryBot.create(:user, name: 'JWahewKjWhebCd',
                                 confirmed_not_spam: false)
      end

      before :each do
        UserSpamScorer.spam_score_threshold = 1
        UserSpamScorer.score_mappings =
          { about_me_includes_currency_symbol?: 20 }
        sign_in user
      end

      after(:each) { UserSpamScorer.reset }

      it 'sets an error message' do
        put :update, params: {
                       user: { about_me: 'http://example.com/$£$£$' }
                     }
        msg = "You can't update your profile text at this time."
        expect(flash[:error]).to eq(msg)
      end

      it 'redirects to the user page' do
        put :update, params: {
                       user: { about_me: 'http://example.com/$£$£$' }
                     }
        expect(response).
          to redirect_to(show_user_path(url_name: user.url_name))
      end

      it 'does not update the user about_me' do
        put :update, params: {
                       user: { about_me: 'http://example.com/$£$£$' }
                     }
        expect(user.reload.about_me).to eq('')
      end
    end

    context 'with spam attributes and a whitelisted user' do
      let(:user) do
        FactoryBot.create(:user, name: 'JWahewKjWhebCd',
                                 confirmed_not_spam: true)
      end

      before :each do
        UserSpamScorer.spam_score_threshold = 1
        UserSpamScorer.score_mappings =
          { about_me_includes_currency_symbol?: 20 }
        sign_in user
      end

      after(:each) { UserSpamScorer.reset }

      it 'updates the user about_me' do
        # By whitelisting we're giving them the benefit of the doubt
        put :update, params: {
                       user: { about_me: 'http://example.com/$£$£$' }
                     }
        expect(user.reload.about_me).to eq('http://example.com/$£$£$')
      end
    end

    context 'with block_spam_about_me_text? returning true, spam content and a non-whitelisted user' do
      let(:user) { FactoryBot.create(:user, confirmed_not_spam: false) }

      before :each do
        UserSpamScorer.score_mappings = {}
        sign_in user
        allow(@controller).
          to receive(:block_spam_about_me_text?).
          and_return(true)
      end

      after(:each) { UserSpamScorer.reset }

      it 'sends an exception notification' do
        put :update,
            params: {
              user: {
                about_me: '[HD] Watch Jason Bourne Online free MOVIE Full-HD'
              }
            }
        mail = deliveries.first
        expect(mail.subject).
          to match(/Spam about me text from user #{ user.id }/)
      end

      it 'sets an error message' do
        put :update,
            params: {
              user: {
                about_me: '[HD] Watch Jason Bourne Online free MOVIE Full-HD'
              }
            }
        msg = "You can't update your profile text at this time."
        expect(flash[:error]).to eq(msg)
      end

      it 'redirects to the user page' do
        put :update,
            params: {
              user: {
                about_me: '[HD] Watch Jason Bourne Online free MOVIE Full-HD'
              }
            }
        expect(response).
          to redirect_to(show_user_path(url_name: user.url_name))
      end

      it 'does not update the user about_me' do
        put :update,
            params: {
              user: {
                about_me: '[HD] Watch Jason Bourne Online free MOVIE Full-HD'
              }
            }
        expect(user.reload.about_me).to eq('')
      end
    end

    context 'with block_spam_about_me_text? returning false, spam content and a whitelisted user' do
      let(:user) do
        FactoryBot.create(:user, name: '12345', confirmed_not_spam: true)
      end

      before :each do
        sign_in user
        allow(@controller).
          to receive(:block_spam_about_me_text?).
          and_return(false)
      end

      it 'updates the user about_me' do
        # By whitelisting we're giving them the benefit of the doubt
        put :update,
            params: {
              user: {
                about_me: '[HD] Watch Jason Bourne Online free MOVIE Full-HD'
              }
            }
        expect(user.reload.about_me).
          to eq('[HD] Watch Jason Bourne Online free MOVIE Full-HD')
      end
    end

    context 'with block_spam_about_me_text? returning true, spam content and a whitelisted user' do
      let(:user) { FactoryBot.create(:user, confirmed_not_spam: true) }

      before :each do
        sign_in user
        allow(@controller).
          to receive(:block_spam_about_me_text?).
          and_return(true)
      end

      it 'updates the user about_me' do
        # By whitelisting we're giving them the benefit of the doubt
        put :update,
            params: {
              user: {
                about_me: '[HD] Watch Jason Bourne Online free MOVIE Full-HD'
              }
            }
        expect(user.reload.about_me).
          to eq('[HD] Watch Jason Bourne Online free MOVIE Full-HD')
      end
    end
  end
end
