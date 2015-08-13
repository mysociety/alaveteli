# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminUserController, "when administering users" do
  render_views

  it "shows the index page" do
    get :index
  end

  it "searches for 'bob'" do
    get :index, :query => "bob"
    expect(assigns[:admin_users]).to eq([ users(:bob_smith_user) ])
  end

  it "shows a user" do
    get :show, :id => users(:bob_smith_user)
  end

  it "logs in as another user" do
    get :login_as,  :id => users(:bob_smith_user).id
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'confirm',
                                    :email_token => get_last_post_redirect.email_token)
  end

  # See also "allows an admin to log in as another user" in spec/integration/admin_spec.rb
end

describe AdminUserController, "when updating a user" do

  it "saves a change to 'can_make_batch_requests'" do
    user = FactoryGirl.create(:user)
    expect(user.can_make_batch_requests?).to be false
    post :update, {:id => user.id, :admin_user => {:can_make_batch_requests => '1',
                                                   :name => user.name,
                                                   :email => user.email,
                                                   :admin_level => user.admin_level,
                                                   :ban_text => user.ban_text,
                                                   :about_me => user.about_me,
                                                   :no_limit => user.no_limit}}
    expect(flash[:notice]).to eq('User successfully updated.')
    expect(response).to be_redirect
    user = User.find(user.id)
    expect(user.can_make_batch_requests?).to be true
  end

end

describe AdminUserController do

  describe 'POST modify_comment_visibility' do

    before(:each) do
      @user = FactoryGirl.create(:user)
      request.env["HTTP_REFERER"] = admin_user_path(@user)
    end

    it 'redirects to the page the admin was previously on' do
      comment = FactoryGirl.create(:visible_comment, :user => @user)

      post :modify_comment_visibility, { :id => @user.id,
                                         :comment_ids => comment.id,
                                         :hide_selected => 'hidden' }

      expect(response).to redirect_to(admin_user_path(@user))
    end

    it 'sets the given comments visibility to hidden' do
      comments = FactoryGirl.create_list(:visible_comment, 3, :user => @user)
      comment_ids = comments.map(&:id)

      post :modify_comment_visibility, { :id => @user.id,
                                         :comment_ids => comment_ids,
                                         :hide_selected => 'hidden' }

      Comment.find(comment_ids).each { |comment| expect(comment).not_to be_visible }
    end

    it 'sets the given comments visibility to visible' do
      comments = FactoryGirl.create_list(:hidden_comment, 3, :user => @user)
      comment_ids = comments.map(&:id)

      post :modify_comment_visibility, { :id => @user.id,
                                         :comment_ids => comment_ids,
                                         :unhide_selected => 'visible' }

      Comment.find(comment_ids).each { |comment| expect(comment).to be_visible }
    end

    it 'only modifes the given list of comments' do
      unaffected_comment = FactoryGirl.create(:hidden_comment, :user => @user)
      affected_comment = FactoryGirl.create(:hidden_comment, :user => @user)

      post :modify_comment_visibility, { :id => @user.id,
                                         :comment_ids => affected_comment.id,
                                         :unhide_selected => 'visible' }

      expect(Comment.find(unaffected_comment)).not_to be_visible
      expect(Comment.find(affected_comment)).to be_visible
    end

    it 'preserves the visibility if a comment is already of the requested visibility' do
      hidden_comment = FactoryGirl.create(:hidden_comment, :user => @user)
      visible_comment = FactoryGirl.create(:visible_comment, :user => @user)
      comment_ids = [hidden_comment.id, visible_comment.id]

      post :modify_comment_visibility, { :id => @user.id,
                                         :comment_ids => comment_ids,
                                         :unhide_selected => 'visible' }

      Comment.find(comment_ids).each { |c| expect(c).to be_visible }
    end

  end

end
