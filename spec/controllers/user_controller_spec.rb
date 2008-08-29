require File.dirname(__FILE__) + '/../spec_helper'

# XXX Use route_for or params_from to check /c/ links better
# http://rspec.info/rdoc-rails/classes/Spec/Rails/Example/ControllerExampleGroup.html

describe UserController, "when showing a user" do
    integrate_views
    fixtures :users, :outgoing_messages, :incoming_messages, :info_requests, :info_request_events
  
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

    it "should assign the user" do
        get :show, :url_name => "bob_smith"
        assigns[:display_user].should == users(:bob_smith_user)
    end

# Error handling not quite good enough for this yet
#    it "should not show unconfirmed users" do
#        get :show, :url_name => "silly_emnameem"
#        assigns[:display_users].should == [ users(:silly_name_user) ]
#    end

end

describe UserController, "when signing in" do
    integrate_views
    fixtures :users

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
        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        session[:user_id].should == users(:bob_smith_user).id
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
        response.should_not send_email
    end

    it "should ask you to confirm your email if it isn't confirmed, after log in" do
        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user_signin => { :email => 'silly@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        response.should render_template('confirm')
        response.should send_email
    end

    it "should confirm your email, log you in and redirect you to where you were after you click an email link" do
        get :signin, :r => "/list"
        post_redirect = get_last_postredirect

        post :signin, { :user_signin => { :email => 'silly@localhost', :password => 'jonespassword' },
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
        session[:user_id].should == users(:silly_name_user).id
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
    end

end

describe UserController, "when signing up" do
    integrate_views
    fixtures :users

    it "should be an error if you type the password differently each time" do
        post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypasswordtwo' } 
        }
        assigns[:user_signup].errors[:password].should_not be_nil
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

    it "should send special 'already signed up' mail if you fill the form in with existing registered email " do
        post :signup, { :user_signup => { :email => 'silly@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypassword' } 
        }
        response.should render_template('confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        deliveries[0].body.should include("when you already") # have an account
    end

    # XXX need to do bob@localhost signup and check that sends different email
end

describe UserController, "when signing out" do
    integrate_views
    fixtures :users

    it "should log you out and redirect to the home page" do
        session[:user_id] = users(:bob_smith_user).id
        get :signout
        session[:user_id].should be_nil
        response.should redirect_to(:controller => 'general', :action => 'frontpage')
    end

    it "should log you out and redirect you to where you were" do
        session[:user_id] = users(:bob_smith_user).id
        get :signout, :r => '/list'
        session[:user_id].should be_nil
        response.should redirect_to(:controller => 'request', :action => 'list')
    end

end

describe UserController, "when sending another user a message" do
    integrate_views
    fixtures :users

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
        mail.body.should include("Bob Smith has used WhatDoTheyKnow to send you the message below")
        mail.body.should include("Just a test!")
        #mail.to_addrs.to_s.should == users(:silly_name_user).name_and_email # XXX fix some nastiness with quoting name_and_email
        mail.from_addrs.to_s.should == users(:bob_smith_user).name_and_email
    end

end

describe UserController, "when changing password" do
    integrate_views
    fixtures :users

    it "should show the email form when not logged in" do
        get :signchange
        response.should render_template('signchange_send_confirm')
    end

    it "should send a confirmation email when logged in normally" do
        session[:user_id] = users(:bob_smith_user).id
        get :signchange
        response.should render_template('signchange_confirm')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body.should include("Please click on the link below to confirm your email address")
    end

    it "should send a confirmation email when have wrong login circumstance" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = "bogus"
        get :signchange
        response.should render_template('signchange_confirm')
    end

    it "should show the password change screen when logged in as special password change mode" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = "change_password"
        get :signchange
        response.should render_template('signchange')
    end
 
    it "should change the password, if you have right to do so" do
        session[:user_id] = users(:bob_smith_user).id
        session[:user_circumstance] = "change_password"

        old_hash = users(:bob_smith_user).hashed_password
        post :signchange, { :user => { :password => 'ooo', :password_confirmation => 'ooo' },
            :submitted_signchange_password => 1
        }
        users(:bob_smith_user).hashed_password.should != old_hash

        response.should redirect_to(:controller => 'user', :action => 'show', :url_name => users(:bob_smith_user).url_name)
    end

    it "should not change the password, if you're not logged in" do
    end

    it "should not change the password, if you're just logged in normally" do
    end

end




