# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'json'

# XXX Use route_for or params_from to check /c/ links better
# http://rspec.rubyforge.org/rspec-rails/1.1.12/classes/Spec/Rails/Example/ControllerExampleGroup.html

describe UserController, "when showing a user" do
    integrate_views
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end
   
    it "should be successful" do
        get :show, :url_name => "bob_smith"
        response.should be_success
    end

    it "should redirect to lower case name if given one with capital letters" do
        get :show, :url_name => "Bob_Smith"
        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    end

    it "should render with 'show' template" do
        get :show, :url_name => "bob_smith"
        response.should render_template('show')
    end

    it "should distinguish between 'my profile' and 'my requests' for logged in users" do
        session[:user_id] = users(:bob_smith_user).id
        get :show, :url_name => "bob_smith", :view => 'requests'
        response.body.should_not include("Change your password")
        response.body.should match(/Your [0-9]+ Freedom of Information requests/)
        get :show, :url_name => "bob_smith", :view => 'profile'
        response.body.should include("Change your password")
        response.body.should_not match(/Your [0-9]+ Freedom of Information requests/)
    end

    it "should assign the user" do
        get :show, :url_name => "bob_smith"
        assigns[:display_user].should == users(:bob_smith_user)
    end

    it "should search the user's contributions" do
        get :show, :url_name => "bob_smith"
        assigns[:xapian_requests].results.map{|x|x[:model].info_request}.should =~ InfoRequest.all(
            :conditions => "user_id = #{users(:bob_smith_user).id}")
        
        get :show, :url_name => "bob_smith", :user_query => "money"
        assigns[:xapian_requests].results.map{|x|x[:model].info_request}.should =~ [
            info_requests(:naughty_chicken_request),
            info_requests(:another_boring_request),
        ]
    end

    it "should not show unconfirmed users" do
        begin
            get :show, :url_name => "unconfirmed_user"
        rescue => e
        end
        e.should be_an_instance_of(ActiveRecord::RecordNotFound)
    end

end

describe UserController, "when signing in" do
    integrate_views

    def get_last_postredirect
        post_redirects = PostRedirect.find_by_sql("select * from post_redirects order by id desc limit 1")
        post_redirects.size.should == 1
        post_redirects[0]
    end

    it "should show sign in / sign up page" do
        get :signin
        response.should have_tag("input#signin_token")
    end

    it "should create post redirect to / when you just go to /signin" do
        get :signin
        post_redirect = get_last_postredirect
        post_redirect.uri.should == "/"
    end

    it "should create post redirect to /list when you click signin on /list" do
        get :signin, :r => "/list"
        post_redirect = get_last_postredirect
        post_redirect.uri.should == "/list"
    end

    it "should show you the sign in page again if you get the password wrong" do
        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'NOTRIGHTPASSWORD' },
            :token => post_redirect.token
        }
        response.should render_template('sign')
    end

    it "should log in when you give right email/password, and redirect to where you were" do
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        session[:user_id].should == users(:bob_smith_user).id
        # response doesn't contain /en/ but redirect_to does...
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
        response.should_not send_email

        ActionController::Routing::Routes.filters = old_filters
    end

    it "should not log you in if you use an invalid PostRedirect token, and shouldn't give 500 error either" do
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

        post_redirect = "something invalid"
        lambda {
            post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                :token => post_redirect
            }
        }.should_not raise_error(NoMethodError)
        post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
            :token => post_redirect }
        response.should render_template('sign')
        assigns[:post_redirect].should == nil

        ActionController::Routing::Routes.filters = old_filters
    end

# No idea how to test this in the test framework :(
#    it "should have set a long lived cookie if they picked remember me, session cookie if they didn't" do
#        get :signin, :r => "/list"
#        response.should render_template('sign')
#        post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' } }
#        session[:user_id].should == users(:bob_smith_user).id
#        raise session.options.to_yaml # check cookie lasts a month
#    end

    it "should ask you to confirm your email if it isn't confirmed, after log in" do
        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        response.should render_template('confirm')
        response.should send_email
    end

    it "should confirm your email, log you in and redirect you to where you were after you click an email link" do
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

        get :signin, :r => "/list"
        post_redirect = get_last_postredirect

        post :signin, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        response.should send_email

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body =~ /(http:\/\/.*(\/c\/(.*)))/
        mail_url = $1
        mail_path = $2
        mail_token = $3

        # check is right confirmation URL
        mail_token.should == post_redirect.email_token
        params_from(:get, mail_path).should == { :controller => 'user', :action => 'confirm', :email_token => mail_token }

        # check confirmation URL works
        session[:user_id].should be_nil
        get :confirm, :email_token => post_redirect.email_token
        session[:user_id].should == users(:unconfirmed_user).id
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)

        ActionController::Routing::Routes.filters = old_filters
    end

    it "should keep you logged in if you click a confirmation link and are already logged in as an admin" do
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

        get :signin, :r => "/list"
        post_redirect = get_last_postredirect

        post :signin, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        response.should send_email

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body =~ /(http:\/\/.*(\/c\/(.*)))/
        mail_url = $1
        mail_path = $2
        mail_token = $3

        # check is right confirmation URL
        mail_token.should == post_redirect.email_token
        params_from(:get, mail_path).should == { :controller => 'user', :action => 'confirm', :email_token => mail_token }

        # Log in as an admin
        session[:user_id] = users(:admin_user).id

        # Get the confirmation URL, and check we’re still Joe
        get :confirm, :email_token => post_redirect.email_token
        session[:user_id].should == users(:admin_user).id
        
        # And the redirect should still work, of course
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)

        ActionController::Routing::Routes.filters = old_filters
    end

end

describe UserController, "when signing up" do
    integrate_views

    it "should be an error if you type the password differently each time" do
        post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypasswordtwo' } 
        }
        assigns[:user_signup].errors[:password].should == 'Please enter the same password twice'
    end

    it "should be an error to sign up with a misformatted email" do
        post :signup, { :user_signup => { :email => 'malformed-email', :name => 'Mr Malformed',
            :password => 'sillypassword', :password_confirmation => 'sillypassword' } 
        }
        assigns[:user_signup].errors[:email].should_not be_nil
    end

    it "should send confirmation mail if you fill in the form right" do
        post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypassword' } 
        }
        response.should render_template('confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        deliveries[0].body.should include("not reveal your email")
    end

    it "should send confirmation mail in other languages or different locales" do
        session[:locale] = "es"
        post :signup, {:user_signup => { :email => 'new@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypassword',
           }
        }
        response.should render_template('confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        deliveries[0].body.should include("No revelaremos su dirección de correo")
    end

    it "should send special 'already signed up' mail if you fill the form in with existing registered email" do
        post :signup, { :user_signup => { :email => 'silly@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypassword' } 
        }
        response.should render_template('confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        
        # This text may span a line break, depending on the length of the SITE_NAME
        deliveries[0].body.should match(/when\s+you\s+already\s+have\s+an/)
    end

    # XXX need to do bob@localhost signup and check that sends different email
end

describe UserController, "when signing out" do
    integrate_views

    it "should log you out and redirect to the home page" do
        session[:user_id] = users(:bob_smith_user).id
        get :signout
        session[:user_id].should be_nil
        response.should redirect_to(:controller => 'general', :action => 'frontpage')
    end

    it "should log you out and redirect you to where you were" do
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

        session[:user_id] = users(:bob_smith_user).id
        get :signout, :r => '/list'
        session[:user_id].should be_nil
        response.should redirect_to(:controller => 'request', :action => 'list')

        ActionController::Routing::Routes.filters = old_filters
    end

end

describe UserController, "when sending another user a message" do
    integrate_views

    it "should redirect to signin page if you go to the contact form and aren't signed in" do
        get :contact, :id => users(:silly_name_user)
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should show contact form if you are signed in" do
        session[:user_id] = users(:bob_smith_user).id
        get :contact, :id => users(:silly_name_user)
        response.should render_template('contact')
    end

    it "should give error if you don't fill in the subject" do
        session[:user_id] = users(:bob_smith_user).id
        post :contact, { :id => users(:silly_name_user), :contact => { :subject => "", :message => "Gah" }, :submitted_contact_form => 1 }
        response.should render_template('contact')
    end

    it "should send the message" do
        session[:user_id] = users(:bob_smith_user).id
        post :contact, { :id => users(:silly_name_user), :contact => { :subject => "Dearest you", :message => "Just a test!" }, :submitted_contact_form => 1 }
        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => users(:silly_name_user).url_name)

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body.should include("Bob Smith has used #{MySociety::Config.get('SITE_NAME')} to send you the message below")
        mail.body.should include("Just a test!")
        #mail.to_addrs.first.to_s.should == users(:silly_name_user).name_and_email # XXX fix some nastiness with quoting name_and_email
        mail.from_addrs.first.to_s.should == users(:bob_smith_user).name_and_email
    end

end

describe UserController, "when changing password" do
    integrate_views

    it "should show the email form when not logged in" do
        get :signchangepassword
        response.should render_template('signchangepassword_send_confirm')
    end

    it "should send a confirmation email when logged in normally" do
        session[:user_id] = users(:bob_smith_user).id
        get :signchangepassword
        response.should render_template('signchangepassword_confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body.should include("Please click on the link below to confirm your email address")
    end

    it "should send a confirmation email when have wrong login circumstance" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = "bogus"
        get :signchangepassword
        response.should render_template('signchangepassword_confirm')
    end

    it "should show the password change screen when logged in as special password change mode" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = "change_password"
        get :signchangepassword
        response.should render_template('signchangepassword')
    end
 
    it "should change the password, if you have right to do so" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = "change_password"

        old_hash = users(:bob_smith_user).hashed_password
        post :signchangepassword, { :user => { :password => 'ooo', :password_confirmation => 'ooo' },
            :submitted_signchangepassword_do => 1
        }
        users(:bob_smith_user).hashed_password.should != old_hash

        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => users(:bob_smith_user).url_name)
    end

    it "should not change the password, if you're not logged in" do
        session[:user_circumstance] = "change_password"

        old_hash = users(:bob_smith_user).hashed_password
        post :signchangepassword, { :user => { :password => 'ooo', :password_confirmation => 'ooo' },
            :submitted_signchange_password => 1
        }
        users(:bob_smith_user).hashed_password.should == old_hash
    end

    it "should not change the password, if you're just logged in normally" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = nil

        old_hash = users(:bob_smith_user).hashed_password
        post :signchangepassword, { :user => { :password => 'ooo', :password_confirmation => 'ooo' },
            :submitted_signchange_password => 1
        }

        users(:bob_smith_user).hashed_password.should == old_hash
    end

end

describe UserController, "when changing email address" do
    integrate_views

    it "should require login" do
        get :signchangeemail

        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should show form for changing email if logged in" do
        @user = users(:bob_smith_user)
        session[:user_id] = @user.id

        get :signchangeemail

        response.should render_template('signchangeemail')
    end

    it "should be an error if the password is wrong, everything else right" do
        @user = users(:bob_smith_user)
        session[:user_id] = @user.id
        
        post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost', 
                :password => 'donotknowpassword', :new_email => 'newbob@localhost' },
            :submitted_signchangeemail_do => 1
        }

        @user.reload
        @user.email.should == 'bob@localhost'
        response.should render_template('signchangeemail')
        assigns[:signchangeemail].errors[:password].should_not be_nil

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 0
    end

    it "should be an error if old email is wrong, everything else right" do
        @user = users(:bob_smith_user)
        session[:user_id] = @user.id
        
        post :signchangeemail, { :signchangeemail => { :old_email => 'bob@moo', 
                :password => 'jonespassword', :new_email => 'newbob@localhost' },
            :submitted_signchangeemail_do => 1
        }

        @user.reload
        @user.email.should == 'bob@localhost'
        response.should render_template('signchangeemail')
        assigns[:signchangeemail].errors[:old_email].should_not be_nil

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 0
    end

    it "should work even if the old email had a case difference" do
        @user = users(:bob_smith_user)
        session[:user_id] = @user.id
        
        post :signchangeemail, { :signchangeemail => { :old_email => 'BOB@localhost', 
                :password => 'jonespassword', :new_email => 'newbob@localhost' },
            :submitted_signchangeemail_do => 1
        }

        response.should render_template('signchangeemail_confirm')
    end

    it "should send confirmation email if you get all the details right" do
        @user = users(:bob_smith_user)
        session[:user_id] = @user.id
        
        post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost', 
                :password => 'jonespassword', :new_email => 'newbob@localhost' },
            :submitted_signchangeemail_do => 1
        }

        @user.reload
        @user.email.should == 'bob@localhost'
        @user.email_confirmed.should == true

        response.should render_template('signchangeemail_confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body.should include("confirm that you want to change")
        mail.to.should == [ 'newbob@localhost' ]

        mail.body =~ /(http:\/\/.*(\/c\/(.*)))/
        mail_url = $1
        mail_path = $2
        mail_token = $3

        # Check confirmation URL works
        session[:user_id] = nil
        session[:user_circumstance].should == nil
        get :confirm, :email_token => mail_token
        session[:user_id].should == users(:bob_smith_user).id
        session[:user_circumstance].should == 'change_email'
        response.should redirect_to(:controller => 'user', :action => 'signchangeemail', :post_redirect => 1)

        # Would be nice to do a follow_redirect! here, but rspec-rails doesn't
        # have one. Instead do an equivalent manually.
        post_redirect = PostRedirect.find_by_email_token(mail_token)
        post_redirect.circumstance.should == 'change_email'
        post_redirect.user.should == users(:bob_smith_user)
        post_redirect.post_params.should == {"submitted_signchangeemail_do"=>"1", 
                "action"=>"signchangeemail", 
                "signchangeemail"=>{
                    "old_email"=>"bob@localhost", 
                    "new_email"=>"newbob@localhost"}, 
                "controller"=>"user"}
        post :signchangeemail, post_redirect.post_params

        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => 'bob_smith')
        flash[:notice].should match(/You have now changed your email address/) 
        @user.reload
        @user.email.should == 'newbob@localhost'
        @user.email_confirmed.should == true
    end

    it "should send special 'already signed up' mail if you try to change your email to one already used" do
        @user = users(:bob_smith_user)
        session[:user_id] = @user.id
        
        post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost', 
                :password => 'jonespassword', :new_email => 'silly@localhost' },
            :submitted_signchangeemail_do => 1
        }

        @user.reload
        @user.email.should == 'bob@localhost'
        @user.email_confirmed.should == true

        response.should render_template('signchangeemail_confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]

        mail.body.should include("perhaps you, just tried to change their")
        mail.to.should == [ 'silly@localhost' ]
    end
end

describe UserController, "when using profile photos" do
    integrate_views

    before do
        @user = users(:bob_smith_user)

        @uploadedfile = File.open(file_fixture_name("parrot.png"))
        @uploadedfile.stub!(:original_filename).and_return('parrot.png')

        @uploadedfile_2 = File.open(file_fixture_name("parrot.jpg"))
        @uploadedfile_2.stub!(:original_filename).and_return('parrot.jpg')
    end
    
    it "should not let you change profile photo if you're not logged in as the user" do
        post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 } 
    end

    it "should return a 404 not a 500 when a profile photo has not been set" do
        @user.profile_photo.should be_nil
        lambda {
            get :get_profile_photo, {:url_name => @user.url_name }
        }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should let you change profile photo if you're logged in as the user" do
        @user.profile_photo.should be_nil
        session[:user_id] = @user.id

        post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 } 

        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
        flash[:notice].should match(/Thank you for updating your profile photo/) 

        @user.reload
        @user.profile_photo.should_not be_nil
    end

    it "should let you change profile photo twice" do
        @user.profile_photo.should be_nil
        session[:user_id] = @user.id

        post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 } 
        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
        flash[:notice].should match(/Thank you for updating your profile photo/) 

        post :set_profile_photo, { :id => @user.id, :file => @uploadedfile_2, :submitted_draft_profile_photo => 1, :automatically_crop => 1 } 
        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
        flash[:notice].should match(/Thank you for updating your profile photo/) 

        @user.reload
        @user.profile_photo.should_not be_nil
    end

    # XXX todo check the two stage javascript cropping (above only tests one stage non-javascript one)
end

describe UserController, "when showing JSON version for API" do
  
    it "should be successful" do
        get :show, :url_name => "bob_smith", :format => "json"

        u = JSON.parse(response.body)
        u.class.to_s.should == 'Hash'

        u['url_name'].should == 'bob_smith'
        u['name'].should == 'Bob Smith'
    end

end




