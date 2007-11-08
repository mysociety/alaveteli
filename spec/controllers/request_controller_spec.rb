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
        session[:user] = users(:bob_smith_user)
        get :frontpage
        response.should have_tag('a', "Sign out")
    end
        

end

describe RequestController, "when listing all requests" do
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
    fixtures :info_requests
  
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
end

# XXX do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{RAILS_ROOT}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

describe RequestController, "when creating a new request" do
    fixtures :info_requests, :public_bodies, :users

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
        post :create, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id
            },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." }
        response.should render_template('new')
    end

    it "should redirect to sign in page when input is good and nobody is logged in" do
        params = { :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." } 
        }
        post :create, params
        # XXX yeuch - no other easy way of getting the token so we can check
        # the redirect URL, as it is by definition opaque to the controller
        # apart from in the place that it redirects to.
        post_redirects = PostRedirect.find_by_sql("select * from post_redirects order by id desc limit 1")
        post_redirects.size.should == 1
        post_redirect = post_redirects[0]
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
        # post_redirect.post_params.should == params # XXX get this working. there's a : vs '' problem amongst others
    end

    it "should create the request and outgoing message and redirect to request page when input is good and somebody is logged in" do
        session[:user] = users(:bob_smith_user)
        post :create, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." }  
        ir_array = InfoRequest.find(:all, :conditions => ["title = ?", "Why is your quango called Geraldine?"])
        ir_array.size.should == 1
        ir = ir_array[0]
        ir.outgoing_messages.size.should == 1
        om = ir.outgoing_messages[0]
        om.body.should == "This is a silly letter. It is too short to be interesting."
        response.should redirect_to(:controller => 'request', :action => 'show', :id => ir.id)
    end
end







