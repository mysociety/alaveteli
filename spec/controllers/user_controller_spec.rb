require 'spec_helper'

RSpec.describe UserController do
  describe 'GET show' do
    let(:user) { FactoryBot.create(:user) }

    it 'renders the show template' do
      get :show, params: { url_name: user.url_name }
      expect(response).to render_template(:show)
    end

    it 'assigns the user' do
      get :show, params: { url_name: user.url_name }
      expect(assigns[:display_user]).to eq(user)
    end

    it 'should be successful' do
      get :show, params: { url_name: user.url_name }
      expect(response).to be_successful
    end

    it 'raises a RecordNotFound for non-existent users' do
      user.destroy!
      expect {
        get :show, params: { url_name: user.url_name }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises a RecordNotFound for unconfirmed users' do
      user = FactoryBot.create(:user, email_confirmed: false)
      expect {
        get :show, params: { url_name: user.url_name }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when user is suspended' do
      it 'adds noindex, nofollow header' do
        user = FactoryBot.create(:user, :banned)
        get :show, params: { url_name: user.url_name }
        expect(response.headers['X-Robots-Tag']).to eq 'noindex, nofollow'
      end
    end

    # TODO: Use route_for or params_from to check /c/ links better
    # http://rspec.rubyforge.org/rspec-rails/1.1.12/classes/Spec/Rails/Example/
    # ControllerExampleGroup.html
    context 'when redirecting a show request to a canonical url' do
      it 'redirects to lower case name if given one with capital letters' do
        get :show, params: { url_name: 'Bob_Smith' }
        expect(response).to redirect_to(show_user_path(url_name: 'bob_smith'))
      end

      it 'redirects a long non-canonical name that has a numerical suffix, retaining the suffix' do
        get :show, params: { url_name: 'Bob_SmithBob_SmithBob_SmithBob_S_2' }
        expect(response).
          to redirect_to(show_user_path('bob_smithbob_smithbob_smithbob_s_2'))
      end

      it 'does not redirect a long canonical name that has a numerical suffix' do
        FactoryBot.create(:user,
                          name: 'Bob Smith Bob Smith Bob Smith Bob Smith')
        FactoryBot.create(:user,
                          name: 'Bob Smith Bob Smith Bob Smith Bob Smith')
        get :show, params: { url_name: 'bob_smith_bob_smith_bob_smith_bo_2' }
        expect(response).to be_successful
      end
    end

    # Also doubles for when not logged in viewing another user's profile
    context 'when viewing a profile' do
      def make_request
        get :show, params: { url_name: user.url_name, view: 'profile' }
      end

      render_views

      it 'does not show requests or batch requests, but does show account options' do
        make_request

        expect(assigns[:show_profile]).to be true
        expect(assigns[:show_requests]).to be false
        expect(assigns[:show_batches]).to be false

        expect(response.body).
          not_to match(/Freedom of Information requests made by this person/)

        expect(response.body).
          to match(/change password, subscriptions and more/)
      end
    end

    # Also doubles for when not logged in viewing another user's requests
    context 'when viewing requests' do
      def make_request
        get :show, params: { url_name: user.url_name, view: 'requests' }
      end

      render_views

      it 'shows requests and batch requests, but does not show account options' do
        make_request

        expect(assigns[:show_profile]).to be false
        expect(assigns[:show_requests]).to be true
        expect(assigns[:show_batches]).to be true

        expect(response.body).
          to match(/Freedom of Information requests made by this person/)

        expect(response.body).
          not_to match(/change password, subscriptions and more/)
      end

      it 'does not show requests and batch requests for a closed user' do
        user.close_and_anonymise
        make_request

        expect(assigns[:show_profile]).to be false
        expect(assigns[:show_requests]).to be false
        expect(assigns[:show_batches]).to be false
      end

      it 'does not show private requests' do
        user = FactoryBot.create(:pro_user)
        FactoryBot.create(:embargoed_request, user: user)
        get :show, params: { url_name: user.url_name, view: 'requests' }
        expect(assigns[:private_requests]).to be_empty
      end
    end

    context 'when logged in viewing your own profile' do
      def make_request
        get :show, params: { url_name: user.url_name, view: 'profile' }
      end

      render_views

      before do
        sign_in user
      end

      it 'does not show requests or batch requests, but does show account options' do
        make_request
        expect(response.body).
          not_to match(/Freedom of Information requests made by you/)
        expect(assigns[:show_batches]).to be false
        expect(response.body).to include('Change your password')
      end
    end

    context 'when logged in viewing your own requests' do
      def make_request
        get :show, params: { url_name: user.url_name, view: 'requests' }
      end

      render_views

      before do
        sign_in user
      end

      it "assigns the user's undescribed requests" do
        info_request = FactoryBot.create(:info_request, user: user)

        allow_any_instance_of(User).
          to receive(:get_undescribed_requests).
            and_return([info_request])

        make_request

        expect(assigns[:undescribed_requests]).to eq([info_request])
      end

      it "assigns the user's track things" do
        search_track = FactoryBot.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things]).to eq([search_track])
      end

      it "assigns the user's grouped track things" do
        search_track = FactoryBot.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things_grouped]).
          to eq('search_query' => [search_track])
      end

      it 'shows requests, batch requests, but not account options' do
        make_request
        expect(response.body).
          to match(/Freedom of Information requests made by you/)
        expect(assigns[:show_batches]).to be true
        expect(response.body).not_to include('Change your password')
      end

      it 'does not include annotations of hidden requests in the count' do
        hidden_request =
          FactoryBot.create(:info_request, prominence: 'hidden')
        comment1 = FactoryBot.create(:visible_comment,
                                     info_request: hidden_request,
                                     user: user)
        FactoryBot.create(:info_request_event,
                          event_type: 'comment',
                          comment: comment1,
                          info_request: hidden_request)

        shown_request = FactoryBot.create(:info_request)
        comment2 = FactoryBot.create(:visible_comment,
                                     info_request: shown_request,
                                     user: user)
        comment_event = FactoryBot.create(:info_request_event,
                                          event_type: 'comment',
                                          comment: comment2,
                                          info_request: shown_request)

        expect(user.reload.comments.size).to eq(2)
        expect(user.reload.comments.visible.size).to eq(1)

        stub_search_results(items: [comment_event], total: 1)

        make_request

        expect(response.body).to match(/Your 1 annotation/)
      end

      it 'shows private requests' do
        user = FactoryBot.create(:pro_user)
        info_request = FactoryBot.create(:embargoed_request, user: user)
        sign_in user
        get :show, params: { url_name: user.url_name, view: 'requests' }
        expect(assigns[:private_requests]).to match_array([info_request])
      end

      it 'does not show hidden private requests' do
        user = FactoryBot.create(:pro_user)
        info_request = FactoryBot.create(:embargoed_request, user: user)
        FactoryBot.create(:embargoed_request, user: user, prominence: 'hidden')
        sign_in user
        get :show, params: { url_name: user.url_name, view: 'requests' }
        expect(assigns[:private_requests]).to match_array([info_request])
      end
    end

    context 'when logged in filtering your own requests' do
      before do
        sign_in user
      end

      it 'filters by the given query' do
        request_1 =
          FactoryBot.create(:info_request, user: user, title: 'Some money?')
        FactoryBot.create(:info_request, user: user, title: 'How many books?')

        event = request_1.info_request_events.first
        stub_search_results(items: [event], total: 1)

        get :show, params: {
                     url_name: user.url_name,
                     view: 'requests',
                     user_query: 'money'
                   }

        actual =
          assigns[:request_results].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'filters private requests by the given query' do
        user = FactoryBot.create(:pro_user)
        request_1 =
          FactoryBot.
          create(:embargoed_request, user: user, title: 'Some money?')
        FactoryBot.
          create(:embargoed_request, user: user, title: 'How many books?')

        sign_in user

        get :show, params: {
                     url_name: user.url_name,
                     view: 'requests',
                     user_query: 'money'
                   }

        expect(assigns[:private_requests]).to match_array([request_1])
      end

      it 'filters by the given query and request status' do
        request_1 =
          FactoryBot.create(:info_request, user: user, title: 'Some money?')
        FactoryBot.create(:successful_request, user: user, title: 'More money')
        FactoryBot.create(:info_request, user: user, title: 'How many books?')

        event = request_1.info_request_events.first
        stub_search_results(items: [event], total: 1)

        get :show, params: {
                     url_name: user.url_name,
                     view: 'requests',
                     user_query: 'money',
                     request_latest_status: 'waiting_response'
                   }

        actual =
          assigns[:request_results].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'filters private requests by the given query and request status' do
        request_1 =
          FactoryBot.
          create(:embargoed_request, user: user, title: 'Some money?')
        FactoryBot.
          create(:embargoed_request, user: user, title: 'How many books?')
        FactoryBot.
          create(:embargoed_request, user: user, title: 'More money').
          set_described_state('successful')

        get :show, params: {
                     url_name: user.url_name,
                     view: 'requests',
                     user_query: 'money',
                     request_latest_status: 'waiting_response'
                   }

        expect(assigns[:private_requests]).to match_array([request_1])
      end
    end

    context 'when logged in viewing other requests' do
      def make_request
        get :show, params: { url_name: user.url_name, view: 'requests' }
      end

      render_views

      before do
        sign_in FactoryBot.create(:user)
      end

      it "does not assign undescribed requests" do
        info_request = FactoryBot.create(:info_request, user: user)

        allow_any_instance_of(User).
          to receive(:get_undescribed_requests).
            and_return([info_request])

        make_request

        expect(assigns[:undescribed_requests]).to be_nil
      end

      it "does not assign the user's track things" do
        search_track = FactoryBot.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things]).to be_nil
      end

      it "does not assign grouped track things" do
        search_track = FactoryBot.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things_grouped]).to be_nil
      end

      it 'shows requests, batch requests, but not account options' do
        make_request
        expect(response.body).
          to match(/Freedom of Information requests made by this person/)
        expect(assigns[:show_batches]).to be true
        expect(response.body).not_to include('Change your password')
      end

      it 'does not include annotations of hidden requests in the count' do
        hidden_request =
          FactoryBot.create(:info_request, prominence: 'hidden')
        comment1 = FactoryBot.create(:visible_comment,
                                     info_request: hidden_request,
                                     user: user)
        FactoryBot.create(:info_request_event,
                           event_type: 'comment',
                           comment: comment1,
                           info_request: hidden_request)

        shown_request = FactoryBot.create(:info_request)
        comment2 = FactoryBot.create(:visible_comment,
                                     info_request: shown_request,
                                     user: user)
        comment_event = FactoryBot.create(:info_request_event,
                                          event_type: 'comment',
                                          comment: comment2,
                                          info_request: shown_request)

        expect(user.reload.comments.size).to eq(2)
        expect(user.reload.comments.visible.size).to eq(1)

        stub_search_results(items: [comment_event], total: 1)

        make_request

        expect(response.body).to match(/This person's 1 annotation/)
      end

      it 'does not show private requests' do
        pro_user = FactoryBot.create(:pro_user)
        info_request = FactoryBot.create(:embargoed_request, user: pro_user)
        get :show, params: { url_name: pro_user.url_name, view: 'requests' }
        expect(assigns[:private_requests]).to be_empty
      end

      it 'does not show hidden private requests' do
        pro_user = FactoryBot.create(:pro_user)
        info_request = FactoryBot.create(:embargoed_request, user: pro_user)
        FactoryBot.
          create(:embargoed_request, user: pro_user, prominence: 'hidden')
        get :show, params: { url_name: pro_user.url_name, view: 'requests' }
        expect(assigns[:private_requests]).to be_empty
      end
    end

    context 'when logged in filtering other requests' do
      before do
        sign_in FactoryBot.create(:user)
      end

      it 'filters by the given query' do
        request_1 =
          FactoryBot.create(:info_request, user: user, title: 'Some money?')
        FactoryBot.create(:info_request, user: user, title: 'How many books?')

        event = request_1.info_request_events.first
        stub_search_results(items: [event], total: 1)

        get :show, params: {
                     url_name: user.url_name,
                     view: 'requests',
                     user_query: 'money'
                   }

        actual =
          assigns[:request_results].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'does not show private requests when filtering by query' do
        pro_user = FactoryBot.create(:pro_user)
        request_1 =
          FactoryBot.
          create(:embargoed_request, user: pro_user, title: 'Some money?')
        FactoryBot.
          create(:embargoed_request, user: pro_user, title: 'How many books?')

        get :show, params: {
                     url_name: pro_user.url_name,
                     view: 'requests',
                     user_query: 'money'
                   }

        expect(assigns[:private_requests]).to be_empty
      end

      it 'filters by the given query and request status' do
        request_1 =
          FactoryBot.create(:info_request, user: user, title: 'Some money?')
        FactoryBot.create(:successful_request, user: user, title: 'More money')
        FactoryBot.create(:info_request, user: user, title: 'How many books?')

        event = request_1.info_request_events.first
        stub_search_results(items: [event], total: 1)

        get :show, params: {
                     url_name: user.url_name,
                     view: 'requests',
                     user_query: 'money',
                     request_latest_status: 'waiting_response'
                   }

        actual =
          assigns[:request_results].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'does not show private requests when filtering by request status' do
        pro_user = FactoryBot.create(:pro_user)
        request_1 =
          FactoryBot.
          create(:embargoed_request, user: pro_user, title: 'Some money?')
        FactoryBot.
          create(:embargoed_request, user: pro_user, title: 'How many books?')
        FactoryBot.
          create(:embargoed_request, user: pro_user, title: 'More money').
          set_described_state('successful')

        get :show, params: {
                     url_name: pro_user.url_name,
                     view: 'requests',
                     user_query: 'money',
                     request_latest_status: 'waiting_response'
                   }

        expect(assigns[:private_requests]).to be_empty
      end
    end
  end

  describe 'POST set_profile_photo' do
    context 'user is banned' do
      before(:each) do
        @user = FactoryBot.create(:user, ban_text: 'Causing trouble')
        sign_in @user
        @uploadedfile = fixture_file_upload("parrot.png")

        post :set_profile_photo, params: {
                                   id: @user.id,
                                   file: @uploadedfile,
                                   submitted_draft_profile_photo: 1,
                                   automatically_crop: 1
                                 }
      end

      it 'redirects to the profile page' do
        expect(response).to redirect_to(set_profile_photo_path)
      end

      it 'renders an error message' do
        msg = 'Suspended users cannot edit their profile'
        expect(flash[:error]).to eq(msg)
      end
    end
  end

  describe 'POST #signup' do
    render_views

    before do
      # Don't call out to external url during tests
      allow(controller).to receive(:country_from_ip).and_return('gb')
    end

    context 'when signups are in read-only mode' do
      before do
        allow(AlaveteliConfiguration).to receive(:read_only_features).
          and_return(['signups'])
      end

      it 'redirects to the frontpage' do
        post :signup, params: {
          user_signup: {
            email: 'new@localhost',
            name: 'New Person',
            password: 'sillypassword',
            password_confirmation: 'sillypassword'
          }
        }
        expect(response).to redirect_to frontpage_url
      end

      it 'shows a default read only flash message' do
        post :signup, params: {
          user_signup: {
            email: 'new@localhost',
            name: 'New Person',
            password: 'sillypassword',
            password_confirmation: 'sillypassword'
          }
        }
        expect(flash[:notice]).to match(/Alaveteli is currently in maintenance/)
      end
    end

    context 'when site is in general read-only mode' do
      before do
        allow(AlaveteliConfiguration).to receive(:read_only).
          and_return('Database upgrade')
      end

      it 'redirects to the frontpage' do
        post :signup, params: {
          user_signup: {
            email: 'new@localhost',
            name: 'New Person',
            password: 'sillypassword',
            password_confirmation: 'sillypassword'
          }
        }
        expect(response).to redirect_to frontpage_url
      end

      it 'shows a flash message' do
        post :signup, params: {
          user_signup: {
            email: 'new@localhost',
            name: 'New Person',
            password: 'sillypassword',
            password_confirmation: 'sillypassword'
          }
        }
        expect(flash[:notice]).to match(/Database upgrade/)
      end
    end

    it "should be an error if you type the password differently each time" do
      post :signup, params: {
                      user_signup: {
                        email: 'new@localhost',
                        name: 'New Person',
                        password: 'sillypassword',
                        password_confirmation: 'sillypasswordtwo'
                      }
                    }
      expect(assigns[:user_signup].errors[:password_confirmation]).
        to eq(['Please enter the same password twice'])
    end

    it "should be an error to sign up with a misformatted email" do
      post :signup, params: {
                      user_signup: {
                        email: 'malformed-email',
                        name: 'Mr Malformed',
                        password: 'sillypassword',
                        password_confirmation: 'sillypassword'
                      }
                    }
      expect(assigns[:user_signup].errors[:email]).
        to eq(['Please enter a valid email address'])
    end

    it "should not show the 'already in use' error when trying to sign up with a duplicate email" do
      existing_user = FactoryBot.create(:user, email: 'in-use@localhost')

      post :signup, params: {
                      user_signup: {
                        email: 'in-use@localhost',
                        name: 'Mr Suspected-Hacker',
                        password: 'sillypassword',
                        password_confirmation: 'mistyped'
                      }
                    }
      expect(assigns[:user_signup].errors[:password_confirmation]).
        to eq(['Please enter the same password twice'])
      expect(assigns[:user_signup].errors[:email]).to be_empty
    end

    it "should send confirmation mail if you fill in the form right" do
      post :signup, params: {
                      user_signup: {
                        email: 'new@localhost',
                        name: 'New Person',
                        password: 'sillypassword',
                        password_confirmation: 'sillypassword'
                      }
                    }
      expect(response).to render_template('confirm')

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      expect(deliveries[0].body).to include("not reveal your email")
    end

    it "should send confirmation mail in other languages or different locales" do
      cookies[:locale] = 'es'
      post :signup, params: {
                      user_signup: {
                        email: 'new@localhost',
                        name: 'New Person',
                        password: 'sillypassword',
                        password_confirmation: 'sillypassword'
                      }
                    }
      expect(response).to render_template('confirm')

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      expect(deliveries[0].body).to include("No revelaremos")
    end

    context "filling in the form with an existing registered email" do
      it "should send special 'already signed up' mail" do
        post :signup, params: {
                        user_signup: {
                          email: 'silly@localhost',
                          name: 'New Person',
                          password: 'sillypassword',
                          password_confirmation: 'sillypassword'
                        }
                      }
        expect(response).to render_template('confirm')

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)

        # This text may span a line break, depending on the length of the
        # SITE_NAME
        expect(deliveries[0].body).to match(/when\s+you\s+already\s+have\s+an/)
      end

      it "cope with trailing spaces in the email address" do
        post :signup, params: {
                        user_signup: {
                          email: 'silly@localhost ',
                          name: 'New Person',
                          password: 'sillypassword',
                          password_confirmation: 'sillypassword'
                        }
                      }
        expect(response).to render_template('confirm')

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)

        # This text may span a line break, depending on the length of the
        # SITE_NAME
        expect(deliveries[0].body).to match(/when\s+you\s+already\s+have\s+an/)
      end

      context 'when the token belongs to a non-normal circumstance' do
        let(:existing_user) { FactoryBot.create(:user) }

        let!(:change_password_redirect) do
          FactoryBot.create(:post_redirect,
                            circumstance: 'change_password',
                            user: existing_user)
        end

        it 'does not rebind the token to the existing user' do
          post :signup, params: {
            token: change_password_redirect.token,
            user_signup: {
              email: 'silly@localhost',
              name: 'New Person',
              password: 'sillypassword',
              password_confirmation: 'sillypassword'
            }
          }

          expect(change_password_redirect.reload.user).to eq(existing_user)
        end
      end

      context 'when a token already has a user (confirmation sent)' do
        let(:user) { FactoryBot.create(:user) }
        let(:other_user) { FactoryBot.create(:user) }

        let!(:claimed_redirect) do
          FactoryBot.create(:post_redirect, circumstance: 'normal', user: user)
        end

        before do
          post :signup, params: {
            token: claimed_redirect.token,
            user_signup: {
              email: other_user.email,
              name: 'New Person',
              password: 'sillypassword',
              password_confirmation: 'sillypassword'
            }
          }
        end

        it 'does not rebind the token to a different user' do
          expect(claimed_redirect.reload.user).to eq(user)
        end

        it 'sends the already-registered email using a fresh token' do
          confirmation = ActionMailer::Base.deliveries.last
          expect(confirmation.body).to match(/when\s+you\s+already\s+have\s+an/)
          expect(confirmation.body).not_to match(claimed_redirect.token)
        end
      end

      context 'when the token already has a user and a new user signs up' do
        let(:user) { FactoryBot.create(:user) }
        let(:new_user) { FactoryBot.build(:user) }

        let!(:claimed_redirect) do
          FactoryBot.create(:post_redirect, circumstance: 'normal', user: user)
        end

        before do
          post :signup, params: {
            token: claimed_redirect.token,
            user_signup: {
              email: new_user.email,
              name: new_user.name,
              password: new_user.password,
              password_confirmation: new_user.password
            }
          }
        end

        it 'does not rebind the token to the newly created user' do
          expect(claimed_redirect.reload.user).to eq(user)
        end

        it 'sends the confirmation email using a fresh token' do
          confirmation = ActionMailer::Base.deliveries.last
          expect(confirmation.body).to match(/confirm\s+your\s+email\s+address/)
          expect(confirmation.body).not_to match(claimed_redirect.token)
        end
      end

      it "should create a new PostRedirect if the old one has expired" do
        allow(PostRedirect).to receive(:find_by).and_return(nil)
        post :signup, params: {
                        user_signup: {
                          email: 'silly@localhost',
                          name: 'New Person',
                          password: 'sillypassword',
                          password_confirmation: 'sillypassword'
                        }
                      }
        expect(response).to render_template('confirm')
      end
    end

    it 'accepts only whitelisted parameters' do
      expect {
        post :signup, params: {
                        user_signup: {
                          email: 'silly@localhost',
                          name: 'New Person',
                          password: 'sillypassword',
                          password_confirmation: 'sillypassword',
                          role_ids: Role.admin_role.id
                        }
                      }
      }.to raise_error(ActionController::UnpermittedParameters)
    end

    context 'when the user_signup param is empty' do
      # Usually automated bots that submit the form without this param
      before { post :signup, params: { foo: {} } }

      it 're-renders the form' do
        expect(response).to render_template(:sign)
      end

      it 'renders a simple error message' do
        expect(flash[:error]).to eq('Invalid form submission')
      end
    end

    context 'when the user is already signed in' do
      let(:user) { FactoryBot.create(:user) }

      before do
        ActionController::Base.allow_forgery_protection = true
      end

      after do
        ActionController::Base.allow_forgery_protection = false
      end

      it "shows the confirmation page for valid credentials" do
        sign_in user
        post :signup, params: { user_signup: {
                                  email: user.email,
                                  name: user.name,
                                  password: 'jonespassword',
                                  password_confirmation: 'jonespassword'
                                }
                              }
        expect(response).to render_template('confirm')
      end
    end

    context 'when the IP is rate limited' do
      before(:each) do
        limiter = double
        allow(limiter).to receive(:record)
        allow(limiter).to receive(:limit?).and_return(true)
        allow(controller).to receive(:ip_rate_limiter).and_return(limiter)
      end

      context 'when block_rate_limited_ips? is true' do
        before(:each) do
          allow(@controller).
            to receive(:block_rate_limited_ips?).and_return(true)
        end

        it 'sends an exception notification' do
          post :signup, params: {
                          user_signup: {
                            email: 'rate-limited@localhost',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Rate limited signup from/)
        end

        it 'blocks the signup' do
          post :signup, params: {
                          user_signup: {
                            email: 'rate-limited@localhost',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(User.where(email: 'rate-limited@localhost').count).to eq(0)
        end

        it 're-renders the form' do
          post :signup, params: {
                          user_signup: {
                            email: 'rate-limited@localhost',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(response).to render_template('sign')
        end

        it 'sets a flash error' do
          post :signup, params: {
                          user_signup: {
                            email: 'rate-limited@localhost',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(flash[:error]).to match(/unable to sign up new users/)
        end
      end

      context 'when block_rate_limited_ips? is false' do
        before(:each) do
          allow(@controller).
            to receive(:block_rate_limited_ips?).and_return(false)
        end

        it 'sends an exception notification' do
          post :signup, params: {
                          user_signup: {
                            email: 'rate-limited@localhost',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Rate limited signup from/)
        end

        it 'allows the signup' do
          post :signup, params: {
                          user_signup: {
                            email: 'rate-limited@localhost',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(User.where(email: 'rate-limited@localhost').count).to eq(1)
        end
      end
    end

    context 'using a spammy name or email from a known spam domain' do
      before do
        spam_scorer = double
        allow(spam_scorer).to receive(:spam?).and_return(true)
        allow(UserSpamScorer).to receive(:new).and_return(spam_scorer)
      end

      context 'when spam_should_be_blocked? is true' do
        before do
          allow(@controller).
            to receive(:spam_should_be_blocked?).and_return(true)
        end

        it 'logs the signup attempt' do
          msg = "Attempted signup from suspected spammer, " \
                "email: spammer@example.com, " \
                "name: 'Download New Person 1080p!'"
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with(msg)

          post :signup, params: {
                          user_signup: {
                            email: 'spammer@example.com',
                            name: 'Download New Person 1080p!',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
        end

        it 'blocks the signup' do
          post :signup, params: {
                          user_signup: {
                            email: 'spammer@example.com',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(User.where(email: 'spammer@example.com').count).to eq(0)
        end

        it 're-renders the form' do
          post :signup, params: {
                          user_signup: {
                            email: 'spammer@example.com',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(response).to render_template('sign')
        end
      end

      context 'when spam_should_be_blocked? is false' do
        before do
          allow(@controller).
            to receive(:spam_should_be_blocked?).and_return(false)
        end

        it 'sends an exception notification' do
          post :signup, params: {
                          user_signup: {
                            email: 'spammer@example.com',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/signup from suspected spammer/)
        end

        it 'allows the signup' do
          post :signup, params: {
                          user_signup: {
                            email: 'spammer@example.com',
                            name: 'New Person',
                            password: 'sillypassword',
                            password_confirmation: 'sillypassword'
                          }
                        }
          expect(User.where(email: 'spammer@example.com').count).to eq(1)
        end
      end
    end

    # TODO: need to do bob@localhost signup and check that sends different email
  end

  describe 'GET tor' do
    subject { get :tor }

    before { subject }

    it 'returns a 403 status' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'sets long cache headers' do
      expect(response.headers['Cache-Control']).to eq('max-age=86400, public')
    end

    it 'renders a plain text message' do
      msg = 'Signups from Tor have been blocked due to extensive misuse. ' \
            'Please contact us if this is a problem for you.'
      expect(response.body).to eq(msg)
    end
  end
end

RSpec.describe UserController, "when changing email address" do
  render_views

  it "should require login" do
    get :signchangeemail
    expect(response).
      to redirect_to(signin_path(token: get_last_post_redirect.token))
  end

  it "should show form for changing email if logged in" do
    @user = users(:bob_smith_user)
    sign_in @user

    get :signchangeemail

    expect(response).to render_template('signchangeemail')
  end

  it "should be an error if the password is wrong, everything else right" do
    @user = users(:bob_smith_user)
    sign_in @user

    post :signchangeemail,
         params: {
           signchangeemail: {
             old_email: 'bob@localhost',
             password: 'donotknowpassword',
             new_email: 'newbob@localhost'
           },
           submitted_signchangeemail_do: 1
         }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(response).to render_template('signchangeemail')
    expect(assigns[:signchangeemail].errors[:password]).not_to be_nil

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  it "should be an error if old email is wrong, everything else right" do
    @user = users(:bob_smith_user)
    sign_in @user

    post :signchangeemail,
         params: {
           signchangeemail: {
             old_email: 'bob@moo',
             password: 'jonespassword',
             new_email: 'newbob@localhost'
           },
           submitted_signchangeemail_do: 1
         }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(response).to render_template('signchangeemail')
    expect(assigns[:signchangeemail].errors[:old_email]).not_to be_nil

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  it "should work even if the old email had a case difference" do
    @user = users(:bob_smith_user)
    sign_in @user

    post :signchangeemail,
         params: {
           signchangeemail: {
             old_email: 'BOB@localhost',
             password: 'jonespassword',
             new_email: 'newbob@localhost'
           },
           submitted_signchangeemail_do: 1
         }

    expect(response).to render_template('signchangeemail_confirm')
  end

  it "should send special 'already signed up' mail if you try to change your email to one already used" do
    @user = users(:bob_smith_user)
    sign_in @user

    post :signchangeemail,
         params: {
           signchangeemail: {
             old_email: 'bob@localhost',
             password: 'jonespassword',
             new_email: 'silly@localhost'
           },
           submitted_signchangeemail_do: 1
         }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(@user.email_confirmed).to eq(true)

    expect(response).to render_template('signchangeemail_confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]

    expect(mail.body).to include("perhaps you, just tried to change their")
    expect(mail.to).to eq([ 'silly@localhost' ])
  end

  it "should record email change in history when email is successfully changed" do
    @user = users(:bob_smith_user)
    sign_in @user

    old_email = @user.email
    new_email = 'newbob@localhost'

    # First, send the confirmation email
    post :signchangeemail, params: {
      signchangeemail: {
        old_email: old_email,
        password: 'jonespassword',
        new_email: new_email
      },
      submitted_signchangeemail_do: 1
    }

    expect(response).to render_template('signchangeemail_confirm')

    # Simulate clicking the confirmation link
    post_redirect = PostRedirect.order(:id).last
    session[:user_circumstance] = 'change_email'
    session[:post_redirect_token] = post_redirect.token

    # Ensure user is still logged in even if login_token has changed
    @user.reload
    sign_in @user

    # Submit the form again with the confirmation token
    post :signchangeemail, params: {
      signchangeemail: {
        old_email: old_email,
        new_email: new_email
      },
      submitted_signchangeemail_do: 1
    }

    @user.reload
    expect(@user.email).to eq(new_email)

    # Check that email history was recorded
    history = @user.email_histories.last
    expect(history).not_to be_nil
    expect(history.old_email).to eq(old_email)
    expect(history.new_email).to eq(new_email)
    expect(history.changed_at).to be_within(1.minute).of(Time.current)
  end

  it 'should not allow changing to an address different from the confirmed one' do
    @user = users(:bob_smith_user)
    sign_in @user

    old_email = @user.email
    confirmed_email = 'confirmed@localhost'
    different_email = 'different@localhost'

    # Step 1: initiate change to confirmed_email
    post :signchangeemail, params: {
      signchangeemail: {
        old_email: old_email,
        password: 'jonespassword',
        new_email: confirmed_email
      },
      submitted_signchangeemail_do: 1
    }

    expect(response).to render_template('signchangeemail_confirm')

    # Step 2: simulate clicking the confirmation link
    post_redirect = PostRedirect.order(:id).last
    session[:user_circumstance] = 'change_email'
    session[:post_redirect_token] = post_redirect.token

    @user.reload
    sign_in @user

    # Step 3: submit with a DIFFERENT new_email than was confirmed
    post :signchangeemail, params: {
      signchangeemail: {
        old_email: old_email,
        new_email: different_email
      },
      submitted_signchangeemail_do: 1
    }

    @user.reload
    expect(@user.email).not_to eq(different_email)
    expect(@user.email).to eq(old_email)
  end
end

RSpec.describe UserController, "when using profile photos" do
  render_views

  before do
    @user = users(:bob_smith_user)

    @uploadedfile = fixture_file_upload("parrot.png")
    @uploadedfile_2 = fixture_file_upload("parrot.png")
  end

  it "should not let you change profile photo if you're not logged in as the user" do
    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }
  end

  it "should return a 404 not a 500 when a profile photo has not been set" do
    expect(@user.profile_photo).to be_nil
    expect {
      get :get_profile_photo, params: { url_name: @user.url_name }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should let you change profile photo if you're logged in as the user" do
    expect(@user.profile_photo).to be_nil
    sign_in @user

    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }

    expect(response).to redirect_to(
      controller: 'user',
      action: 'show',
      url_name: "bob_smith"
    )
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  context 'there is no profile text' do
    let(:user) { FactoryBot.create(:user, about_me: '') }

    it 'prompts you to add profile text when adding a photo' do
      sign_in user

      profile_photo = ProfilePhoto.
                        create(data: load_file_fixture("parrot.png"),
                               user: user)

      post :set_profile_photo,
           params: {
             id: user.id,
             file: @uploadedfile,
             submitted_crop_profile_photo: 1,
             draft_profile_photo_id: profile_photo.id
           }

      expect(flash[:notice][:partial]).
        to eq("user/update_profile_photo")
    end
  end

  it "should let you change profile photo twice" do
    expect(@user.profile_photo).to be_nil
    sign_in @user

    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }
    expect(response).to redirect_to(
      controller: 'user',
      action: 'show',
      url_name: "bob_smith"
    )
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile_2,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }
    expect(response).to redirect_to(
      controller: 'user',
      action: 'show',
      url_name: "bob_smith"
    )
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  # TODO: todo check the two stage javascript cropping (above only tests one
  # stage non-javascript one)
end

RSpec.describe UserController, "when showing JSON version for API" do
  it "should be successful" do
    get :show, params: { url_name: "bob_smith", format: "json" }

    u = JSON.parse(response.body)
    expect(u.class.to_s).to eq('Hash')

    expect(u['url_name']).to eq('bob_smith')
    expect(u['name']).to eq('Bob Smith')
  end
end

RSpec.describe UserController, "when viewing the river" do
  let(:user) { FactoryBot.create(:user) }

  it 'gathers the events matching every track the user has' do
    request_track = FactoryBot.create(:request_update_track,
                                      tracking_user: user)
    search_track = FactoryBot.create(:search_track, tracking_user: user)
    older = mock_model(InfoRequestEvent, created_at: 2.hours.ago)
    newer = mock_model(InfoRequestEvent, created_at: 1.hour.ago)

    stub_search_results(items: [])
    allow(Search).to receive(:search).
      with(request_track.track_query, any_args).
      and_return(double(results: build_search_results(
        items: [{ model: older }]
      )))
    allow(Search).to receive(:search).
      with(search_track.track_query, any_args).
      and_return(double(results: build_search_results(
        items: [{ model: newer }]
      )))

    sign_in user
    get :river

    expect(assigns[:results]).to eq([newer, older])
  end

  it 'has no results for a visitor who is not logged in' do
    get :river

    expect(assigns[:results]).to be_empty
  end
end

RSpec.describe UserController, "when viewing the wall" do
  it 'orders feed results by created_at descending' do
    user = FactoryBot.create(:user)

    old_event = mock_model(InfoRequestEvent, created_at: 2.days.ago)
    new_event = mock_model(InfoRequestEvent, created_at: 1.hour.ago)
    stub_search_results(items: [old_event, new_event])

    get :wall, params: { url_name: user.url_name }

    expect(assigns[:feed_results]).to eq([new_event, old_event])
  end

  it 'includes events matching the tracks the user owns' do
    user = FactoryBot.create(:user)
    track_thing = FactoryBot.create(:search_track, tracking_user: user)
    tracked_event = mock_model(InfoRequestEvent, created_at: 1.hour.ago)

    searcher = double
    stub_search_results(items: [])
    allow(Search).to receive(:search).
      with(track_thing.track_query, hash_including(sort_by: 'described_at')).
      and_return(searcher)
    expect(searcher).to receive(:results).
      with(page: 1, per_page: 20).
      and_return(build_search_results(items: [tracked_event]))

    sign_in user
    get :wall, params: { url_name: user.url_name }

    expect(assigns[:feed_results]).to eq([tracked_event])
  end

  it 'does not return feed results for closed users' do
    user = FactoryBot.create(:user, :closed)

    event = mock_model(InfoRequestEvent, created_at: 1.hour.ago)
    stub_search_results(items: [event])

    get :wall, params: { url_name: user.url_name }

    expect(assigns[:feed_results]).to be_empty
  end

  it "should allow users to turn their own email alerts on and off" do
    user = users(:silly_name_user)
    sign_in user
    expect(user.receive_email_alerts).to eq(true)
    get :set_receive_email_alerts, params: {
                                     receive_email_alerts: 'false',
                                     came_from: "/"
                                   }
    user.reload
    expect(user.receive_email_alerts).not_to eq(true)
  end

  it 'adds noindex, nofollow header' do
    user = FactoryBot.create(:user)
    get :wall, params: { url_name: user.url_name }
    expect(response.headers['X-Robots-Tag']).to eq 'noindex, nofollow'
  end
end
