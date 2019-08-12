# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminUserController do

  describe 'GET index' do

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

    it 'responds successfully' do
      get :index
      expect(response).to be_success
    end

    it 'sets a default sort order' do
      get :index
      expect(assigns[:sort_order]).to eq('name_asc')
    end

    it 'assigns the sort options' do
      sort_options = { 'name_asc' => 'name ASC',
                       'name_desc' => 'name DESC',
                       'created_at_desc' => 'created_at DESC',
                       'created_at_asc' => 'created_at ASC',
                       'updated_at_desc' => 'updated_at DESC',
                       'updated_at_asc' => 'updated_at ASC' }
      get :index
      expect(assigns[:sort_options]).to eq(sort_options)
    end

    it 'assigns a custom sort order if valid' do
      get :index, params: { :sort_order => 'created_at_asc' }
      expect(assigns[:sort_order]).to eq('created_at_asc')
    end

    it 'uses the default sort order if a custom sort order is invalid' do
      get :index, params: { :sort_order => 'invalid' }
      expect(assigns[:sort_order]).to eq('name_asc')
    end

    it 'sorts the records by name_asc' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Bob')
      u2 = FactoryBot.create(:user, :name => 'Alice')
      get :index, params: { :sort_order => 'name_asc' }
      expect(assigns[:admin_users]).to eq([u2, u1])
    end

    it 'sorts the records by name_desc' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Alice')
      u2 = FactoryBot.create(:user, :name => 'Bob')
      get :index, params: { :sort_order => 'name_desc' }
      expect(assigns[:admin_users]).to eq([u2, u1])
    end

    it 'sorts the records by created_at_asc' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Bob')
      u2 = FactoryBot.create(:user, :name => 'Alice')
      get :index, params: { :sort_order => 'created_at_asc' }
      expect(assigns[:admin_users]).to eq([u1, u2])
    end

    it 'sorts the records by created_at_desc' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Alice')
      u2 = FactoryBot.create(:user, :name => 'Bob')
      get :index, params: { :sort_order => 'created_at_desc' }
      expect(assigns[:admin_users]).to eq([u2, u1])
    end

    it 'sorts the records by updated_at_asc' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Alice')
      u2 = FactoryBot.create(:user, :name => 'Bob')
      u1.touch
      get :index, params: { :sort_order => 'updated_at_asc' }
      expect(assigns[:admin_users]).to eq([u2, u1])
    end

    it 'sorts the records by updated_at_desc' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Bob')
      u2 = FactoryBot.create(:user, :name => 'Alice')
      u1.touch
      get :index, params: { :sort_order => 'updated_at_desc' }
      expect(assigns[:admin_users]).to eq([u1, u2])
    end

    it "assigns users matching a case-insensitive query to the view" do
      user = FactoryBot.create(:user, :name => 'Bob Smith')
      get :index, params: { :query => 'bob' }
      expect(assigns[:admin_users].include?(user)).to be true
    end

    it 'strips the string when searching' do
      user = FactoryBot.create(:user, email: 'julie@example.com')
      get :index, params: { query: ' julie@example.com ' }
      expect(assigns[:admin_users]).to include(user)
    end

    it 'will search the about me text' do
      user = FactoryBot.create(:user, about_me: 'http://example.com')
      get :index, params: { query: 'http' }
      expect(assigns[:admin_users]).to include(user)
    end

    it 'searches and sorts the records' do
      User.destroy_all
      u1 = FactoryBot.create(:user, :name => 'Alice Smith')
      u2 = FactoryBot.create(:user, :name => 'Bob Smith')
      u3 = FactoryBot.create(:user, :name => 'John Doe')
      get :index, params: { :query => 'smith', :sort_order => 'name_desc' }
      expect(assigns[:admin_users]).to eq([u2, u1])
    end

    it 'filters the records by role' do
      User.destroy_all
      admin_user = FactoryBot.create(:admin_user)
      user = FactoryBot.create(:user)
      get :index, params: { :roles => [ 'admin' ] }
      expect(assigns[:admin_users]).to eq([admin_user])
    end

    it 'filters the records by multiple roles' do
      User.destroy_all
      admin_user = FactoryBot.create(:admin_user)
      pro_user = FactoryBot.create(:pro_user)
      user = FactoryBot.create(:user)
      get :index, params: { :roles => [ 'admin', 'pro' ] }
      expect(assigns[:admin_users]).to eq([admin_user, pro_user])
    end

  end

  describe 'GET #show' do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    it "is successful" do
      get :show, params: { :id => FactoryBot.create(:user) },
                 session: { :user_id => admin_user.id }
      expect(response).to be_success
    end

    it "assigns the user's info requests to the view" do
      get :show, params: { :id => info_request.user },
                 session: { :user_id => admin_user.id }
      expect(assigns[:info_requests]).to eq([info_request])
    end

    it 'does not include embargoed requests if the current user is
        not a pro admin user' do
      info_request.create_embargo
      get :show, params: { :id => info_request.user },
                 session: { :user_id => admin_user.id }
      expect(assigns[:info_requests]).to eq([])
    end

    context 'when pro is enabled' do

      it 'does not include embargoed requests if the current user is
          not a pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          info_request.create_embargo
          get :show, params: { :id => info_request.user },
                     session: { :user_id => admin_user.id }
          expect(assigns[:info_requests]).to eq([])
        end
      end

      it 'includes embargoed requests if the current user is a pro admin user
          and pro is enabled' do
        with_feature_enabled(:alaveteli_pro) do
          info_request.create_embargo
          get :show, params: { :id => info_request.user },
                     session: { :user_id => pro_admin_user.id }
          expect(assigns[:info_requests].include?(info_request)).to be true
        end
      end

    end

    it "assigns the user's comments to the view" do
      comment = FactoryBot.create(:comment, :info_request => info_request,
                                            :user => info_request.user)
      get :show, params: { :id => info_request.user },
                 session: { :user_id => admin_user.id }
      expect(assigns[:comments]).to eq([comment])
    end

    it 'does not include comments on embargoed requests if the current user is
        not a pro admin user' do
      comment = FactoryBot.create(:comment, :info_request => info_request,
                                            :user => info_request.user)
      info_request.create_embargo
      get :show, params: { :id => info_request.user },
                 session: { :user_id => admin_user.id }
      expect(assigns[:comments]).to eq([])
    end

    context 'when pro is enabled' do

      it 'does not include comments on embargoed requests if the current user is
          not a pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          comment = FactoryBot.create(:comment, :info_request => info_request,
                                                :user => info_request.user)
          info_request.create_embargo
          get :show, params: { :id => info_request.user },
                     session: { :user_id => admin_user.id }
          expect(assigns[:comments]).to eq([])
        end
      end

      it 'includes comments on embargoed requests if the current user is a
          pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          comment = FactoryBot.create(:comment, :info_request => info_request,
                                                :user => info_request.user)
          info_request.create_embargo
          get :show, params: { :id => info_request.user },
                     session: { :user_id => pro_admin_user.id }
          expect(assigns[:comments]).to eq([comment])
        end
      end

    end

  end

  describe "POST #update" do

    let(:admin_user) { FactoryBot.create(:admin_user) }

    before do
      allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)
    end

    it "saves a change to 'can_make_batch_requests'" do
      user = FactoryBot.create(:user)
      expect(user.can_make_batch_requests?).to be false
      post :update, params: { :id => user.id,
                              :admin_user => {
                                :can_make_batch_requests => '1',
                                :name => user.name,
                                :email => user.email,
                                :ban_text => user.ban_text,
                                :about_me => user.about_me,
                                :no_limit => user.no_limit,
                                :confirmed_not_spam => user.confirmed_not_spam
                              }
                            },
                    session: { :user_id => admin_user.id }
      expect(flash[:notice]).to eq('User successfully updated.')
      expect(response).to be_redirect
      user = User.find(user.id)
      expect(user.can_make_batch_requests?).to be true
    end

    it "should not allow an existing email address to be used" do
      existing_email = 'donotreuse@localhost'
      FactoryBot.create(:user, :email => existing_email)
      user = FactoryBot.create(:user, :email => 'user1@localhost')
      post :update, params: { :id => user.id,
                              :admin_user => {
                                :name => user.name,
                                :email => existing_email,
                                :ban_text => user.ban_text,
                                :about_me => user.about_me,
                                :no_limit => user.no_limit,
                                :confirmed_not_spam => user.confirmed_not_spam
                              }
                            },
                    session: { :user_id => admin_user.id }
      user = User.find(user.id)
      expect(user.email).to eq('user1@localhost')
    end

    it "sets the user's roles" do
      user = FactoryBot.create(:user)
      admin_role = Role.where(:name => 'admin').first
      expect(user.is_admin?).to be false
      post :update, params: { :id => user.id,
                              :admin_user => {
                                :name => user.name,
                                :ban_text => user.ban_text,
                                :about_me => user.about_me,
                                :role_ids => [ admin_role.id ],
                                :no_limit => user.no_limit,
                                :confirmed_not_spam => user.confirmed_not_spam
                              }
                            },
                    session: { :user_id => admin_user.id }
      user = User.find(user.id)
      expect(user.is_admin?).to be true
    end

    it "unsets the user's roles if no role ids are supplied" do
      expect(admin_user.is_admin?).to be true
      post :update, params: { :id => admin_user.id,
                              :admin_user => {
                                :name => admin_user.name,
                                :ban_text => admin_user.ban_text,
                                :about_me => admin_user.about_me,
                                :no_limit => admin_user.no_limit,
                                :confirmed_not_spam =>
                                  admin_user.confirmed_not_spam
                              }
                            },
                    session: { :user_id => admin_user.id }
      user = User.find(admin_user.id)
      expect(user.is_admin?).to be false
    end

    it 'does not set a role the setter cannot grant and revoke' do
      user = FactoryBot.create(:user)
      pro_role = Role.where(:name => 'pro').first
      expect(user.is_pro?).to be false
      post :update, params: { :id => user.id,
                              :admin_user => {
                                :name => user.name,
                                :ban_text => user.ban_text,
                                :about_me => user.about_me,
                                :role_ids => [pro_role.id],
                                :no_limit => user.no_limit,
                                :confirmed_not_spam => user.confirmed_not_spam
                              }
                            },
                    session: { :user_id => admin_user.id }
      expect(flash[:error]).to eq("Not permitted to change roles")
      user = User.find(user.id)
      expect(user.is_pro?).to be false
    end

    it 'does not set a role that does not exist' do
      user = FactoryBot.create(:user)
      role_id = Role.maximum(:id) + 1
      expect(user.is_pro?).to be false
      post :update, params: { :id => user.id,
                              :admin_user => {
                                :name => user.name,
                                :ban_text => user.ban_text,
                                :about_me => user.about_me,
                                :role_ids => [role_id],
                                :no_limit => user.no_limit,
                                :confirmed_not_spam => user.confirmed_not_spam
                              }
                            },
                    session: { :user_id => admin_user.id }
      user = User.find(user.id)
      expect(user.is_pro?).to be false
    end

  end

  describe 'POST modify_comment_visibility' do

    before(:each) do
      @user = FactoryBot.create(:user)
      request.env["HTTP_REFERER"] = admin_user_path(@user)
    end

    it 'redirects to the page the admin was previously on' do
      comment = FactoryBot.create(:visible_comment, :user => @user)

      post :modify_comment_visibility, params: {
                                         :id => @user.id,
                                         :comment_ids => comment.id,
                                         :hide_selected => 'hidden'
                                       }

      expect(response).to redirect_to(admin_user_path(@user))
    end

    it 'sets the given comments visibility to hidden' do
      comments = FactoryBot.create_list(:visible_comment, 3, :user => @user)
      comment_ids = comments.map(&:id)

      post :modify_comment_visibility, params: {
                                         :id => @user.id,
                                         :comment_ids => comment_ids,
                                         :hide_selected => 'hidden'
                                       }

      Comment.find(comment_ids).each { |comment| expect(comment).not_to be_visible }
    end

    it 'sets the given comments visibility to visible' do
      comments = FactoryBot.create_list(:hidden_comment, 3, :user => @user)
      comment_ids = comments.map(&:id)

      post :modify_comment_visibility, params: {
                                         :id => @user.id,
                                         :comment_ids => comment_ids,
                                         :unhide_selected => 'visible'
                                       }

      Comment.find(comment_ids).each { |comment| expect(comment).to be_visible }
    end

    it 'only modifes the given list of comments' do
      unaffected_comment = FactoryBot.create(:hidden_comment, :user => @user)
      affected_comment = FactoryBot.create(:hidden_comment, :user => @user)

      post :modify_comment_visibility, params: {
                                         :id => @user.id,
                                         :comment_ids => affected_comment.id,
                                         :unhide_selected => 'visible'
                                       }

      expect(Comment.find(unaffected_comment.id)).not_to be_visible
      expect(Comment.find(affected_comment.id)).to be_visible
    end

    it 'preserves the visibility if a comment is already of the requested visibility' do
      hidden_comment = FactoryBot.create(:hidden_comment, :user => @user)
      visible_comment = FactoryBot.create(:visible_comment, :user => @user)
      comment_ids = [hidden_comment.id, visible_comment.id]

      post :modify_comment_visibility, params: {
                                         :id => @user.id,
                                         :comment_ids => comment_ids,
                                         :unhide_selected => 'visible'
                                       }

      Comment.find(comment_ids).each { |c| expect(c).to be_visible }
    end

  end

end
