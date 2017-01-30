# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CommentController, "when commenting on a request" do
  render_views

  it 'returns a 404 when the info request is embargoed' do
    embargoed_request = FactoryGirl.create(:embargoed_request)
    expect{ post :new, :url_title => embargoed_request.url_title,
                       :comment => { :body => "Some content" },
                       :type => 'request',
                       :submitted_comment => 1,
                       :preview => 1 }
      .to raise_error ActiveRecord::RecordNotFound
  end

  it "should give an error and render 'new' template when body text is just some whitespace" do
    post :new, :url_title => info_requests(:naughty_chicken_request).url_title,
      :comment => { :body => "   " },
      :type => 'request', :submitted_comment => 1, :preview => 1
    expect(assigns[:comment].errors[:body]).not_to be_nil
    expect(response).to render_template('new')
  end

  it "should show preview when input is good" do
    post :new, :url_title => info_requests(:naughty_chicken_request).url_title,
      :comment => { :body => "A good question, but why not also ask about nice chickens?" },
      :type => 'request', :submitted_comment => 1, :preview => 1
    expect(response).to render_template('preview')
  end

  it "should redirect to sign in page when input is good and nobody is logged in" do
    params = { :url_title => info_requests(:naughty_chicken_request).url_title,
               :comment => { :body => "A good question, but why not also ask about nice chickens?" },
               :type => 'request', :submitted_comment => 1, :preview => 0
               }
    post :new, params
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
    # post_redirect.post_params.should == params # TODO: get this working. there's a : vs '' problem amongst others
  end

  it "should create the comment, and redirect to request page when input is good and somebody is logged in" do
    session[:user_id] = users(:bob_smith_user).id

    post :new, :url_title => info_requests(:naughty_chicken_request).url_title,
      :comment => { :body => "A good question, but why not also ask about nice chickens?" },
      :type => 'request', :submitted_comment => 1, :preview => 0

    comment_array = Comment.where(:body => "A good question, but why not " \
                                           "also ask about nice chickens?")
    expect(comment_array.size).to eq(1)
    comment = comment_array[0]

    expect(ActionMailer::Base.deliveries.size).to eq(0)

    expect(response).to redirect_to(:controller => 'request', :action => 'show', :url_title => info_requests(:naughty_chicken_request).url_title)
  end

  it "should give an error if the same request is submitted twice" do
    session[:user_id] = users(:silly_name_user).id

    post :new, :url_title => info_requests(:fancy_dog_request).url_title,
      :comment => { :body => comments(:silly_comment).body },
      :type => 'request', :submitted_comment => 1, :preview => 0

    expect(response).to render_template('new')
  end

  it "should not allow comments if comments are not allowed on the request" do
    session[:user_id] = users(:silly_name_user).id
    info_request = info_requests(:spam_1_request)

    post :new, :url_title => info_request.url_title,
      :comment => { :body => "I demand to be heard!" },
      :type => 'request', :submitted_comment => 1, :preview => 0

    expect(response).to redirect_to(show_request_path(info_request.url_title))
    expect(flash[:notice]).to eq('Comments are not allowed on this request')
  end

  it "should not allow comments if comments are not allowed globally" do
    allow(controller).to receive(:feature_enabled?).with(:annotations).and_return(false)
    session[:user_id] = users(:silly_name_user).id
    info_request = info_requests(:fancy_dog_request)

    post :new, :url_title => info_request.url_title,
      :comment => { :body => "I demand to be heard!" },
      :type => 'request', :submitted_comment => 1, :preview => 0

    expect(response).to redirect_to(show_request_path(info_request.url_title))
    expect(flash[:notice]).to eq('Comments are not allowed on this request')
  end

  it "should not allow comments from banned users" do
    allow_any_instance_of(User).to receive(:ban_text).and_return('Banned from commenting')

    user = users(:silly_name_user)
    session[:user_id] = user.id

    post :new, :url_title => info_requests(:fancy_dog_request).url_title,
      :comment => { :body => comments(:silly_comment).body },
      :type => 'request', :submitted_comment => 1, :preview => 0

    expect(response).to render_template('user/banned')
  end

  describe 'when anti-spam is enabled' do

    before(:each) do
      allow(AlaveteliConfiguration).
        to receive(:enable_anti_spam).and_return(true)
    end

    describe 'when handling a comment that looks like spam' do

      let(:user) { FactoryGirl.create(:user,
                                  :locale => 'en',
                                  :name => 'bob',
                                  :confirmed_not_spam => false) }
      let(:body) { FactoryGirl.create(:public_body) }
      let(:request) { FactoryGirl.create(:info_request) }

      it 'shows an error message' do
        session[:user_id] = user.id
        post :new, :url_title => request.url_title,
          :comment => { :body => "[HD] Watch Jason Bourne Online free MOVIE Full-HD" },
          :type => 'request', :submitted_comment => 1, :preview => 0
        expect(flash[:error])
          .to eq("Sorry, we're currently not able to add your annotation. Please try again later.")
      end

      it 'renders the compose interface' do
        session[:user_id] = user.id
        post :new, :url_title => request.url_title,
          :comment => { :body => "[HD] Watch Jason Bourne Online free MOVIE Full-HD" },
          :type => 'request', :submitted_comment => 1, :preview => 0
        expect(response).to render_template('new')
      end

      it 'allows the comment if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        session[:user_id] = user.id
        post :new, :url_title => request.url_title,
          :comment => { :body => "[HD] Watch Jason Bourne Online free MOVIE Full-HD" },
          :type => 'request', :submitted_comment => 1, :preview => 0
        expect(response).to redirect_to show_request_path(request.url_title)
      end

    end

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
        expect(response).to be_success
      end

    end

  end

end
