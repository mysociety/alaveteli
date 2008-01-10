require File.dirname(__FILE__) + '/../spec_helper'

describe RequestController, "when showing the front page" do
    integrate_views
    fixtures :users

    it "should be successful" do
        get :frontpage
        response.should be_success
    end

    it "should have sign in/up link when not signed in" do
        get :frontpage
        response.should have_tag('a', "Sign in or sign up")
    end

    it "should have sign out link when signed in" do
        session[:user_id] = users(:bob_smith_user).id
        get :frontpage
        response.should have_tag('a', "Sign out")
    end
        

end

describe RequestController, "when listing all requests" do
    integrate_views
    fixtures :info_requests
  
    it "should be successful" do
        get :list
        response.should be_success
    end

    it "should render with 'list' template" do
        get :list
        response.should render_template('list')
    end

    it "should assign the first page of results" do
        # XXX probably should load more than one page of requests into db here :)
        
        get :list
        assigns[:info_requests].should == [ 
            info_requests(:naughty_chicken_request), # reverse-chronological order
            info_requests(:fancy_dog_request)
        ]
    end
end

describe RequestController, "when showing one request" do
    integrate_views
    fixtures :info_requests, :public_bodies, :users, :incoming_messages, :outgoing_messages # all needed as integrating views
  
    it "should be successful" do
        get :show, :id => 101
        response.should be_success
    end

    it "should render with 'show' template" do
        get :show, :id => 101
        response.should render_template('show')
    end

    it "should assign the request" do
        get :show, :id => 101
        assigns[:info_request].should == info_requests(:fancy_dog_request)
    end

    it "should show incoming messages" do
        get :show, :id => 101
        size_before = assigns[:correspondences].size

        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)

        get :show, :id => 101
        (assigns[:correspondences].size - size_before).should == 1
    end
end

# XXX do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{RAILS_ROOT}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

describe RequestController, "when creating a new request" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :public_bodies, :users

    it "should render with 'new' template" do
        get :new
        response.should render_template('new')
    end

    it "should accept a public body parameter posted from the front page" do
        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id } 
        assigns[:info_request].public_body.should == public_bodies(:geraldine_public_body)    
        response.should render_template('new')
    end

    it "should give an error and render 'new' template when a summary isn't given" do
        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1
        response.should render_template('new')
    end

    it "should redirect to sign in page when input is good and nobody is logged in" do
        params = { :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1
        }
        post :new, params
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
        # post_redirect.post_params.should == params # XXX get this working. there's a : vs '' problem amongst others
    end

    it "should create the request and outgoing message and redirect to request page when input is good and somebody is logged in" do
        session[:user_id] = users(:bob_smith_user).id
        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1
        ir_array = InfoRequest.find(:all, :conditions => ["title = ?", "Why is your quango called Geraldine?"])
        ir_array.size.should == 1
        ir = ir_array[0]
        ir.outgoing_messages.size.should == 1
        om = ir.outgoing_messages[0]
        om.body.should == "This is a silly letter. It is too short to be interesting."
        response.should redirect_to(:controller => 'request', :action => 'show', :id => ir.id)
    end

    it "should give an error if the same request is submitted twice" do
        post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id, 
            :title => info_requests(:fancy_dog_request).title},
            :outgoing_message => { :body => info_requests(:fancy_dog_request).outgoing_messages[0].body},
            :submitted_new_request => 1
        response.should render_template('new')
    end
end

describe RequestController, "when viewing an individual response" do
    integrate_views
    fixtures :info_requests, :public_bodies, :users, :incoming_messages, :outgoing_messages # all needed as integrating views
  
    it "should show the response" do
        get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
        response.should render_template('show_response')
    end
end

describe RequestController, "when classifying an individual response" do
    integrate_views
    fixtures :info_requests, :public_bodies, :users, :incoming_messages, :outgoing_messages # all needed as integrating views

    it "should require login" do
        post :show_response, :incoming_message => { :contains_information => true }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_classify => 1
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should not classify response if logged in as wrong user" do
        session[:user_id] = users(:silly_name_user).id
        post :show_response, :incoming_message => { :contains_information => true }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_classify => 1
        response.should render_template('user/wrong_user')
    end

    it "should successfully classify response if logged in as user controlling request" do
        incoming_messages(:useless_incoming_message).user_classified.should == false
        session[:user_id] = users(:bob_smith_user).id
        post :show_response, :incoming_message => { :contains_information => true }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_classify => 1
        response.should redirect_to(:controller => 'request', :action => 'show', :id => info_requests(:fancy_dog_request))
        incoming_messages(:useless_incoming_message).reload
        incoming_messages(:useless_incoming_message).user_classified.should == true
    end
end






