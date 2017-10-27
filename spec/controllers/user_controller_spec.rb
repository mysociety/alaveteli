# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserController do

  describe 'POST set_profile_photo' do

    context 'user is banned' do

      before(:each) do
        @user = FactoryGirl.create(:user, :ban_text => 'Causing trouble')
        session[:user_id] = @user.id
        @uploadedfile = fixture_file_upload("/files/parrot.png")

        post :set_profile_photo, :id => @user.id,
          :file => @uploadedfile,
          :submitted_draft_profile_photo => 1,
          :automatically_crop => 1
      end

      it 'redirects to the profile page' do
        expect(response).to redirect_to(set_profile_photo_path)
      end

      it 'renders an error message' do
        msg = 'Banned users cannot edit their profile'
        expect(flash[:error]).to eq(msg)
      end

    end

  end

end

# TODO: Use route_for or params_from to check /c/ links better
# http://rspec.rubyforge.org/rspec-rails/1.1.12/classes/Spec/Rails/Example/ControllerExampleGroup.html
describe UserController, "when redirecting a show request to a canonical url" do

  it "should redirect to lower case name if given one with capital letters" do
    get :show, :url_name => "Bob_Smith"
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
  end

  it 'should redirect a long non-canonical name that has a numerical suffix,
    retaining the suffix' do
    get :show, :url_name => 'Bob_SmithBob_SmithBob_SmithBob_S_2'
    expect(response).to redirect_to(:controller => 'user',
                                :action => 'show',
                                :url_name => 'bob_smithbob_smithbob_smithbob_s_2')
  end

  it 'should not redirect a long canonical name that has a numerical suffix' do
    user = FactoryGirl.create(:user, :name => 'Bob Smith Bob Smith Bob Smith Bob Smith')
    second_user = FactoryGirl.create(:user, :name => 'Bob Smith Bob Smith Bob Smith Bob Smith')
    get :show, :url_name => 'bob_smith_bob_smith_bob_smith_bo_2'
    expect(response).to be_success
  end

end

describe UserController, "when showing a user" do

  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  it "should be successful" do
    get :show, :url_name => @user.url_name
    expect(response).to be_success
  end

  it "should render with 'show' template" do
    get :show, :url_name => @user.url_name
    expect(response).to render_template('show')
  end

  it "should assign the user" do
    get :show, :url_name => @user.url_name
    expect(assigns[:display_user]).to eq(@user)
  end

  context "when viewing the user's own profile" do

    render_views

    def make_request
      get :show, {:url_name => @user.url_name, :view => 'profile'}, {:user_id => @user.id}
    end

    it 'should not show requests, or batch requests, but should show account options' do
      make_request
      expect(response.body).not_to match(/Freedom of Information requests made by you/)
      expect(assigns[:show_batches]).to be false
      expect(response.body).to include("Change your password")
    end

  end

  context 'when the user being shown is logged in' do

    it "assigns the user's undescribed requests" do
      info_request = FactoryGirl.create(:info_request, :user => @user)
      allow_any_instance_of(User).
        to receive(:get_undescribed_requests).
          and_return([info_request])
      get :show, {:url_name => @user.url_name, :view => 'requests'}, {:user_id => @user.id}
      expect(assigns[:undescribed_requests]).to eq([info_request])
    end

    it "assigns the user's track things" do
      search_track = FactoryGirl.create(:search_track, :tracking_user => @user)
      get :show, {:url_name => @user.url_name, :view => 'requests'}, {:user_id => @user.id}
      expect(assigns[:track_things]).to eq([search_track])
    end

    it "assigns the user's grouped track things" do
      search_track = FactoryGirl.create(:search_track, :tracking_user => @user)
      get :show, {:url_name => @user.url_name, :view => 'requests'}, {:user_id => @user.id}
      expect(assigns[:track_things_grouped]).to eq({'search_query' => [search_track]})
    end

  end

  context "when viewing a user's own requests" do

    render_views

    def make_request
      get :show, {:url_name => @user.url_name, :view => 'requests'}, {:user_id => @user.id}
    end

    it 'should show requests, batch requests, but no account options' do
      make_request
      expect(response.body).to match(/Freedom of Information requests made by you/)
      expect(assigns[:show_batches]).to be true
      expect(response.body).not_to include("Change your password")
    end

    it 'should not include annotations of hidden requests in the count' do
      hidden_request = FactoryGirl.create(:info_request, :prominence => "hidden")
      shown_request = FactoryGirl.create(:info_request)
      comment1 = FactoryGirl.create(:visible_comment,
                                    :info_request => hidden_request,
                                    :user => @user)
      comment2 = FactoryGirl.create(:visible_comment,
                                    :info_request => shown_request,
                                    :user => @user)
      FactoryGirl.create(:info_request_event,
                         :event_type => 'comment',
                         :comment => comment1,
                         :info_request => hidden_request)
      FactoryGirl.create(:info_request_event,
                         :event_type => 'comment',
                         :comment => comment2,
                         :info_request => shown_request)
      expect(@user.reload.comments.size).to eq(2)
      expect(@user.reload.comments.visible.size).to eq(1)
      update_xapian_index

      make_request
      expect(response.body).to match(/Your 1 annotation/)
    end
  end

end

describe UserController, "when showing a user" do

  context 'when using fixture data' do

    before do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    it "should search the user's contributions" do
      user = users(:bob_smith_user)

      get :show, :url_name => "bob_smith"
      actual =
        assigns[:xapian_requests].results.map { |x| x[:model].info_request }

      expect(actual).to match_array(user.info_requests)
    end

    it 'filters by the given query' do
      user = users(:bob_smith_user)

      get :show, :url_name => user.url_name, :user_query => "money"
      actual =
        assigns[:xapian_requests].results.map { |x| x[:model].info_request }

      expect(actual).to match_array([info_requests(:naughty_chicken_request),
                                     info_requests(:another_boring_request)])
    end

    it 'filters by the given query and request status' do
      user = users(:bob_smith_user)

      get :show, :url_name => user.url_name,
                 :user_query => 'money',
                 :request_latest_status => 'waiting_response'
      actual =
        assigns[:xapian_requests].results.map{ |x| x[:model].info_request }

      expect(actual).to match_array([info_requests(:naughty_chicken_request)])
    end

    it 'should not show unconfirmed users' do
      expect { get :show, :url_name => 'unconfirmed_user' }.
        to raise_error(ActiveRecord::RecordNotFound)
    end
  end

end

describe UserController, "when signing up" do
  render_views

  before do
    # Don't call out to external url during tests
    allow(controller).to receive(:country_from_ip).and_return('gb')
  end

  it "should be an error if you type the password differently each time" do
    post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
                                      :password => 'sillypassword', :password_confirmation => 'sillypasswordtwo' }
                    }
    expect(assigns[:user_signup].errors[:password_confirmation]).
      to eq(['Please enter the same password twice'])
  end

  it "should be an error to sign up with a misformatted email" do
    post :signup, { :user_signup => { :email => 'malformed-email', :name => 'Mr Malformed',
                                      :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
    expect(assigns[:user_signup].errors[:email]).to eq(['Please enter a valid email address'])
  end

  it "should not show the 'already in use' error when trying to sign up with a duplicate email" do
    existing_user = FactoryGirl.create(:user, :email => 'in-use@localhost')

    post :signup, { :user_signup => { :email => 'in-use@localhost', :name => 'Mr Suspected-Hacker',
                                      :password => 'sillypassword', :password_confirmation => 'mistyped' }
                    }
    expect(assigns[:user_signup].errors[:password_confirmation]).
      to eq(['Please enter the same password twice'])
    expect(assigns[:user_signup].errors[:email]).to be_empty
  end

  it "should send confirmation mail if you fill in the form right" do
    post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
                                      :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
    expect(response).to render_template('confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    expect(deliveries[0].body).to include("not reveal your email")
  end

  it "should send confirmation mail in other languages or different locales" do
    session[:locale] = "es"
    post :signup, {:user_signup => { :email => 'new@localhost', :name => 'New Person',
                                     :password => 'sillypassword', :password_confirmation => 'sillypassword',
                                     }
                   }
    expect(response).to render_template('confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    expect(deliveries[0].body).to include("No revelaremos")
  end

  context "filling in the form with an existing registered email" do
    it "should send special 'already signed up' mail" do
      post :signup, { :user_signup => { :email => 'silly@localhost', :name => 'New Person',
                                        :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
      expect(response).to render_template('confirm')

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to  eq(1)

      # This text may span a line break, depending on the length of the SITE_NAME
      expect(deliveries[0].body).to match(/when\s+you\s+already\s+have\s+an/)
    end

    it "cope with trailing spaces in the email address" do
      post :signup, { :user_signup => { :email => 'silly@localhost ', :name => 'New Person',
                                        :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
      expect(response).to render_template('confirm')

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to  eq(1)

      # This text may span a line break, depending on the length of the SITE_NAME
      expect(deliveries[0].body).to match(/when\s+you\s+already\s+have\s+an/)
    end

    it "should create a new PostRedirect if the old one has expired" do
      allow(PostRedirect).to receive(:find_by_token).and_return(nil)
      post :signup, { :user_signup => { :email => 'silly@localhost', :name => 'New Person',
                                        :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
      expect(response).to render_template('confirm')
    end
  end

  it 'accepts only whitelisted parameters' do
    expect {
      post :signup, { :user_signup =>
                      { :email => 'silly@localhost',
                        :name => 'New Person',
                        :password => 'sillypassword',
                        :password_confirmation => 'sillypassword',
                        :role_ids => Role.admin_role.id } }
    }.to raise_error(ActionController::UnpermittedParameters)
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
        allow(@controller).to receive(:block_rate_limited_ips?).and_return(true)
      end

      it 'sends an exception notification' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Rate limited signup from/)
      end

      it 'blocks the signup' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'rate-limited@localhost').count).to eq(0)
      end

      it 're-renders the form' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(response).to render_template('sign')
      end

      it 'sets a flash error' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(flash[:error]).to match(/unable to sign up new users/)
      end

    end

    context 'when block_rate_limited_ips? is false' do

      before(:each) do
        allow(@controller).
          to receive(:block_rate_limited_ips?).and_return(false)
      end

      it 'sends an exception notification' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Rate limited signup from/)
      end

      it 'allows the signup' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'rate-limited@localhost').count).to eq(1)
      end

    end

  end

  context 'using a known spam domain' do

    before do
      spam_scorer = double
      allow(spam_scorer).
        to receive(:email_from_spam_domain?).and_return(true)
      allow(UserSpamScorer).to receive(:new).and_return(spam_scorer)
    end

    context 'when block_spam_email_domains? is true' do

      before do
        allow(@controller).
          to receive(:block_spam_email_domains?).and_return(true)
      end

      it 'logs the signup attempt' do
        msg = "Attempted signup from spam domain email: spammer@example.com"
        expect(Rails.logger).to receive(:info).with(msg)

        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
      end

      it 'blocks the signup' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'spammer@example.com').count).to eq(0)
      end

      it 're-renders the form' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(response).to render_template('sign')
      end

      it 'sets a flash error' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(flash[:error]).to match(/unable to sign up new users/)
      end

    end

    context 'when block_spam_email_domains? is false' do

      before do
        allow(@controller).
          to receive(:block_spam_email_domains?).and_return(false)
      end

      it 'sends an exception notification' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).
          to match(/signup from spam domain email: spammer@example\.com/)
      end

      it 'allows the signup' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'spammer@example.com').count).to eq(1)
      end

    end

  end

  # TODO: need to do bob@localhost signup and check that sends different email
end

describe UserController, "when sending another user a message" do
  render_views

  it "should redirect to signin page if you go to the contact form and aren't signed in" do
    get :contact, :id => users(:silly_name_user)
    expect(response).
      to redirect_to(signin_path(:token => get_last_post_redirect.token))
  end

  it "should show contact form if you are signed in" do
    session[:user_id] = users(:bob_smith_user).id
    get :contact, :id => users(:silly_name_user)
    expect(response).to render_template('contact')
  end

  it "should give error if you don't fill in the subject" do
    session[:user_id] = users(:bob_smith_user).id
    post :contact, { :id => users(:silly_name_user), :contact => { :subject => "", :message => "Gah" }, :submitted_contact_form => 1 }
    expect(response).to render_template('contact')
  end

  it "should send the message" do
    session[:user_id] = users(:bob_smith_user).id
    post :contact, { :id => users(:silly_name_user), :contact => { :subject => "Dearest you", :message => "Just a test!" }, :submitted_contact_form => 1 }
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => users(:silly_name_user).url_name)

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]
    expect(mail.body).to include("Bob Smith has used #{AlaveteliConfiguration::site_name} to send you the message below")
    expect(mail.body).to include("Just a test!")
    #mail.to_addrs.first.to_s.should == users(:silly_name_user).name_and_email # TODO: fix some nastiness with quoting name_and_email
    expect(mail.header['Reply-To'].to_s).to match(users(:bob_smith_user).email)
  end

end

describe UserController, "when changing email address" do
  render_views

  it "should require login" do
    get :signchangeemail
    expect(response).
      to redirect_to(signin_path(:token => get_last_post_redirect.token))
  end

  it "should show form for changing email if logged in" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    get :signchangeemail

    expect(response).to render_template('signchangeemail')
  end

  it "should be an error if the password is wrong, everything else right" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost',
                                                   :password => 'donotknowpassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(response).to render_template('signchangeemail')
    expect(assigns[:signchangeemail].errors[:password]).not_to be_nil

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(0)
  end

  it "should be an error if old email is wrong, everything else right" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@moo',
                                                   :password => 'jonespassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(response).to render_template('signchangeemail')
    expect(assigns[:signchangeemail].errors[:old_email]).not_to be_nil

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(0)
  end

  it "should work even if the old email had a case difference" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'BOB@localhost',
                                                   :password => 'jonespassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    expect(response).to render_template('signchangeemail_confirm')
  end

  it "should send special 'already signed up' mail if you try to change your email to one already used" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost',
                                                   :password => 'jonespassword', :new_email => 'silly@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(@user.email_confirmed).to eq(true)

    expect(response).to render_template('signchangeemail_confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]

    expect(mail.body).to include("perhaps you, just tried to change their")
    expect(mail.to).to eq([ 'silly@localhost' ])
  end
end

describe UserController, "when using profile photos" do
  render_views

  before do
    @user = users(:bob_smith_user)

    @uploadedfile = fixture_file_upload("/files/parrot.png")
    @uploadedfile_2 = fixture_file_upload("/files/parrot.jpg")
  end

  it "should not let you change profile photo if you're not logged in as the user" do
    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }
  end

  it "should return a 404 not a 500 when a profile photo has not been set" do
    expect(@user.profile_photo).to be_nil
    expect {
      get :get_profile_photo, {:url_name => @user.url_name }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should let you change profile photo if you're logged in as the user" do
    expect(@user.profile_photo).to be_nil
    session[:user_id] = @user.id

    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }

    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  context 'there is no profile text' do
    let(:user) { FactoryGirl.create(:user, :about_me => '') }

    it 'prompts you to add profile text when adding a photo' do
      session[:user_id] = user.id

      profile_photo = ProfilePhoto.
                        create(:data => load_file_fixture("parrot.png"),
                               :user => user)

      post :set_profile_photo, { :id => user.id,
                                 :file => @uploadedfile,
                                 :submitted_crop_profile_photo => 1,
                                 :draft_profile_photo_id => profile_photo.id }

      expect(flash[:notice][:partial]).
        to eq("user/update_profile_photo.html.erb")
    end

  end

  it "should let you change profile photo twice" do
    expect(@user.profile_photo).to be_nil
    session[:user_id] = @user.id

    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile_2, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  # TODO: todo check the two stage javascript cropping (above only tests one stage non-javascript one)
end

describe UserController, "when showing JSON version for API" do

  it "should be successful" do
    get :show, :url_name => "bob_smith", :format => "json"

    u = JSON.parse(response.body)
    expect(u.class.to_s).to eq('Hash')

    expect(u['url_name']).to eq('bob_smith')
    expect(u['name']).to eq('Bob Smith')
  end

end

describe UserController, "when viewing the wall" do
  render_views

  before(:each) do
    load_raw_emails_data
    get_fixtures_xapian_index
  end

  it "should show users stuff on their wall, most recent first" do
    user = users(:silly_name_user)
    ire = info_request_events(:useless_incoming_message_event)
    ire.created_at = DateTime.new(2001,1,1)
    session[:user_id] = user.id
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results][0]).not_to eq(ire)

    ire.created_at = Time.zone.now
    ire.save!
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results][0]).to eq(ire)
  end

  it "should show other users' activities on their walls" do
    user = users(:silly_name_user)
    ire = info_request_events(:useless_incoming_message_event)
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results][0]).not_to eq(ire)
  end

  it "should allow users to turn their own email alerts on and off" do
    user = users(:silly_name_user)
    session[:user_id] = user.id
    expect(user.receive_email_alerts).to eq(true)
    get :set_receive_email_alerts, :receive_email_alerts => 'false', :came_from => "/"
    user.reload
    expect(user.receive_email_alerts).not_to eq(true)
  end

  it 'should not show duplicate feed results' do
    user = users(:silly_name_user)
    session[:user_id] = user.id
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results].uniq).to eq(assigns[:feed_results])
  end

end
