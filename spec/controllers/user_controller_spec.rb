require File.dirname(__FILE__) + '/../spec_helper'

describe UserController, "when showing a user" do
    integrate_views
    fixtures :users
  
    it "should be successful" do
        get :show, :simple_name => "bob-smith"
        response.should be_success
    end

    it "should redirect to lower case name if given one with capital letters" do
        get :show, :simple_name => "Bob-Smith"
        response.should redirect_to(:controller => 'user', :action => 'show', :simple_name => "bob-smith")
    end

    it "should render with 'show' template" do
        get :show, :simple_name => "bob-smith"
        response.should render_template('show')
    end

    it "should assign the user" do
        get :show, :simple_name => "bob-smith"
        assigns[:display_users].should == [ users(:bob_smith_user) ]
    end
    
    it "should assign the user for a more complex name" do
        get :show, :simple_name => "silly-emnameem"
        assigns[:display_users].should == [ users(:silly_name_user) ]
    end


    # XXX test for 404s when don't give valid name
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
        post :signin, { :user => { :email => 'bob@localhost', :password => 'NOTRIGHTPASSWORD' },
            :token => post_redirect.token
        }
        response.should render_template('signin')
    end

    it "should log in when you give right email/password, and redirect to where you were" do
        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user => { :email => 'bob@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        session[:user].should == users(:bob_smith_user).id
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
        response.should_not send_email
    end

    it "should ask you to confirm your email if it isn't confirmed, after log in" do
        get :signin, :r => "/list"
        response.should render_template('sign')
        post_redirect = get_last_postredirect
        post :signin, { :user => { :email => 'silly@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        response.should render_template('confirm')
        response.should send_email
    end

    it "should confirm your email, log you in and redirect you to where you were after you click an email link" do
        get :signin, :r => "/list"
        post_redirect = get_last_postredirect

        post :signin, { :user => { :email => 'silly@localhost', :password => 'jonespassword' },
            :token => post_redirect.token
        }
        response.should send_email

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.body =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        get :confirm, :email_token => post_redirect.email_token
        response.should redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
    end

end

describe UserController, "when signing up" do
    integrate_views
    fixtures :users

    it "should be an error if you type the password differently each time" do
        post :signup, { :user => { :email => 'new@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypasswordtwo' } 
        }
        assigns[:user].errors[:password].should_not be_nil
    end

    it "should be an error to sign up with an email that has already been used" do
        post :signup, { :user => { :email => 'bob@localhost', :name => 'Second Bob',
            :password => 'sillypassword', :password_confirmation => 'sillypassword' } 
        }
        assigns[:user].errors[:email].should_not be_nil
    end

    it "should ask you to confirm your email if you fill in the form right" do
        post :signup, { :user => { :email => 'new@localhost', :name => 'New Person',
            :password => 'sillypassword', :password_confirmation => 'sillypassword' } 
        }
        response.should render_template('confirm')
        # XXX if you go straight into signup form without token it doesn't make one
    end
end

describe UserController, "when signing out" do
    integrate_views
    fixtures :users

    it "should log you out and redirect to the home page" do
        session[:user] = users(:bob_smith_user).id
        get :signout
        session[:user].should be_nil
        response.should redirect_to(:controller => 'request', :action => 'frontpage')
    end

    it "should log you out and redirect you to where you were" do
        session[:user] = users(:bob_smith_user).id
        get :signout, :r => '/list'
        session[:user].should be_nil
        response.should redirect_to(:controller => 'request', :action => 'list')
    end

end

