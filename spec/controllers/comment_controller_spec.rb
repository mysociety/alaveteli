require File.dirname(__FILE__) + '/../spec_helper'

describe CommentController, "when commenting on a request" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :public_bodies, :users, :comments

    it "should give an error and render 'new' template when body text is just some whitespace" do
        post :new, :url_title => info_requests(:naughty_chicken_request).url_title,
            :comment => { :body => "   " },
            :type => 'request', :submitted_comment => 1, :preview => 1
        assigns[:comment].errors[:body].should_not be_nil
        response.should render_template('new')
    end

    it "should show preview when input is good" do
        post :new, :url_title => info_requests(:naughty_chicken_request).url_title,
            :comment => { :body => "A good question, but why not also ask about nice chickens?" },
            :type => 'request', :submitted_comment => 1, :preview => 1
        response.should render_template('preview')
    end

    it "should redirect to sign in page when input is good and nobody is logged in" do
        params = { :url_title => info_requests(:naughty_chicken_request).url_title,
            :comment => { :body => "A good question, but why not also ask about nice chickens?" },
            :type => 'request', :submitted_comment => 1, :preview => 0
        }
        post :new, params
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
        # post_redirect.post_params.should == params # XXX get this working. there's a : vs '' problem amongst others
    end

    it "should create the comment, and redirect to request page when input is good and somebody is logged in" do
        session[:user_id] = users(:bob_smith_user).id
        post :new, :url_title => info_requests(:naughty_chicken_request).url_title,
            :comment => { :body => "A good question, but why not also ask about nice chickens?" },
            :type => 'request', :submitted_comment => 1, :preview => 0

        comment_array = Comment.find(:all, :conditions => ["body = ?", "A good question, but why not also ask about nice chickens?"])
        comment_array.size.should == 1
        comment = comment_array[0]

        ActionMailer::Base.deliveries.size.should == 0

        response.should redirect_to(:controller => 'request', :action => 'show', :url_title => info_requests(:naughty_chicken_request).url_title, :anchor => 'comment-' + comment.id.to_s)
    end

#    it "should give an error if the same request is submitted twice" do
#        session[:user_id] = users(:bob_smith_user).id
#
#        # We use raw_body here, so white space is the same
#        post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id, 
#            :title => info_requests(:fancy_dog_request).title },
#            :outgoing_message => { :body => info_requests(:fancy_dog_request).outgoing_messages[0].raw_body},
#            :submitted_new_request => 1, :preview => 0, :mouse_house => 1
#        response.should render_template('new')
#    end

#    it "should give an error if the same request is submitted twice with extra whitespace in the body" do
#        # This only works for PostgreSQL databases which have regexp_replace -
#        # see model method InfoRequest.find_by_existing_request for more info
#        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
#            session[:user_id] = users(:bob_smith_user).id
#
#            post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id, 
#                :title => info_requests(:fancy_dog_request).title },
#                :outgoing_message => { :body => "\n" + info_requests(:fancy_dog_request).outgoing_messages[0].body + " "},
#                :submitted_new_request => 1, :preview => 0, :mouse_house => 1
#            response.should render_template('new')
#        end
#    end

end



