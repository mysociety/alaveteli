# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CommentController, "when commenting on a request" do
  render_views

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
    # post_redirect.post_params.should == params # TODO: get this working. there's a : vs '' problem amongst others
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

    response.should redirect_to(:controller => 'request', :action => 'show', :url_title => info_requests(:naughty_chicken_request).url_title)
  end

  it "should give an error if the same request is submitted twice" do
    session[:user_id] = users(:silly_name_user).id

    post :new, :url_title => info_requests(:fancy_dog_request).url_title,
      :comment => { :body => comments(:silly_comment).body },
      :type => 'request', :submitted_comment => 1, :preview => 0

    response.should render_template('new')
  end

  it "should not allow comments if comments are not allowed" do
    session[:user_id] = users(:silly_name_user).id
    info_request = info_requests(:spam_1_request)

    post :new, :url_title => info_request.url_title,
      :comment => { :body => "I demand to be heard!" },
      :type => 'request', :submitted_comment => 1, :preview => 0

    response.should redirect_to(show_request_path(info_request.url_title))
    flash[:notice].should == 'Comments are not allowed on this request'
  end

  it "should not allow comments from banned users" do
    User.any_instance.stub(:ban_text).and_return('Banned from commenting')

    user = users(:silly_name_user)
    session[:user_id] = user.id

    post :new, :url_title => info_requests(:fancy_dog_request).url_title,
      :comment => { :body => comments(:silly_comment).body },
      :type => 'request', :submitted_comment => 1, :preview => 0

    response.should render_template('user/banned')
  end

  describe 'when commenting on an external request' do

    describe 'when responding to a GET request on a successful request' do

      before do
        @external_request = info_requests(:external_request)
        @external_request.described_state = 'successful'
        @external_request.save!
      end

      it 'should be successful' do
        get :new, :url_title => @external_request.url_title,
          :type => 'request'
        response.should be_success
      end

    end

  end

end
