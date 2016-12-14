# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCensorRuleController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET index' do

    before do
      @global_rules = 3.times.map { FactoryGirl.create(:global_censor_rule) }
      get :index
    end

    it 'returns a successful response' do
      expect(response).to be_success
    end

    it 'collects admin censor rules' do
      FactoryGirl.create(:info_request_censor_rule)
      FactoryGirl.create(:public_body_censor_rule)
      FactoryGirl.create(:user_censor_rule)
      expect(assigns[:censor_rules]).to match_array(@global_rules)
    end

    it 'renders the correct template' do
      expect(response).to render_template('index')
    end

  end

  describe 'GET new' do

    context 'global censor rule' do

      before do
        get :new
      end

      it 'returns a successful response' do
        expect(response).to be_success
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'does not associate the censor rule with an info request' do
        expect(assigns[:censor_rule].info_request).to be_nil
      end

      it 'does not associate the censor rule with a public body' do
        expect(assigns[:censor_rule].public_body).to be_nil
      end

      it 'does not associate the censor rule with a user' do
        expect(assigns[:censor_rule].user).to be_nil
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_censor_rules_path)
      end

    end

    context 'request_id param' do

      before do
        @info_request = FactoryGirl.create(:info_request)
        get :new, :request_id => @info_request.id
      end

      it 'returns a successful response' do
        expect(response).to be_success
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'finds an info request if the request_id param is supplied' do
        expect(assigns[:info_request]).to eq(@info_request)
      end

      it 'associates the info request with the new censor rule' do
        expect(assigns[:censor_rule].info_request).to eq(@info_request)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_request_censor_rules_path(@info_request))
      end

    end

    context 'user_id param' do

      before do
        @user = FactoryGirl.create(:user)
        get :new, :user_id => @user.id
      end

      it 'returns a successful response' do
        expect(response).to be_success
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'finds a user if the user_id param is supplied' do
        expect(assigns[:censor_user]).to eq(@user)
      end

      it 'associates the user with the new censor rule' do
        expect(assigns[:censor_rule].user).to eq(@user)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_user_censor_rules_path(@user))
      end

    end

    # NOTE: This should be public_body_id but the resource is mapped as :bodies
    context 'body_id param' do

      before do
        @public_body = FactoryGirl.create(:public_body)
        get :new, :body_id => @public_body.id
      end

      it 'returns a successful response' do
        expect(response).to be_success
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'finds a public body if the public_body_id param is supplied' do
        expect(assigns[:public_body]).to eq(@public_body)
      end

      it 'associates the public_body with the new censor rule' do
        expect(assigns[:censor_rule].public_body).to eq(@public_body)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_body_censor_rules_path(@public_body))
      end

    end

  end

  describe 'POST create' do

    context 'a global censor rule' do

      before(:each) do
        @censor_rule_params = FactoryGirl.attributes_for(:global_censor_rule)
        # last_edit_editor gets set in the controller
        @censor_rule_params.delete(:last_edit_editor)
      end

      def create_censor_rule
        post :create, :censor_rule => @censor_rule_params
      end

      it 'sets the last_edit_editor to the current admin' do
        create_censor_rule
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'does not associate the censor rule with an info request' do
        create_censor_rule
        expect(assigns[:censor_rule].info_request).to be_nil
      end

      it 'does not associate the censor rule with a public body' do
        create_censor_rule
        expect(assigns[:censor_rule].public_body).to be_nil
      end

      it 'does not associate the censor rule with a user' do
        create_censor_rule
        expect(assigns[:censor_rule].user).to be_nil
      end

      it 'sets the URL for the form to POST to' do
        create_censor_rule
        expect(assigns[:form_url]).to eq(admin_censor_rules_path)
      end

      context 'successfully saving the censor rule' do

        it 'redirects to the censor rules index' do
          create_censor_rule
          expect(response).to redirect_to(
            admin_censor_rules_path
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          create_censor_rule
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          create_censor_rule
          expect(response).to render_template('new')
        end

      end

    end

    context 'request_id param' do

      before(:each) do
        @censor_rule_params = FactoryGirl.attributes_for(:info_request_censor_rule)
        # last_edit_editor gets set in the controller
        @censor_rule_params.delete(:last_edit_editor)
        @info_request = FactoryGirl.create(:info_request)
        post :create, :request_id => @info_request.id,
                      :censor_rule => @censor_rule_params
      end

      it 'sets the last_edit_editor to the current admin' do
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'finds an info request if the request_id param is supplied' do
        expect(assigns[:info_request]).to eq(@info_request)
      end

      it 'associates the info request with the new censor rule' do
        expect(assigns[:censor_rule].info_request).to eq(@info_request)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_request_censor_rules_path(@info_request))
      end

      context 'successfully saving the censor rule' do

        it 'persists the censor rule' do
          post :create, :censor_rule => @censor_rule_params,
                        :request_id => @info_request.id
          expect(assigns[:censor_rule]).to be_persisted
        end

        it 'confirms the censor rule is created' do
          post :create, :censor_rule => @censor_rule_params,
                        :request_id => @info_request.id
          msg = 'Censor rule was successfully created.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'purges the cache for the info request' do
          info_request = FactoryGirl.create(:info_request)
          censor_rules = double
          allow(info_request).to receive(:censor_rules) { censor_rules }
          allow(InfoRequest).to receive(:find) { info_request }
          censor_rule = FactoryGirl.build(:info_request_censor_rule, :info_request => info_request)
          allow(censor_rules).to receive(:build) { censor_rule }

          expect(info_request).to receive(:expire)

          post :create, :censor_rule => @censor_rule_params,
                        :request_id => info_request.id
        end

        it 'redirects to the associated info request' do
          post :create, :censor_rule => @censor_rule_params,
                        :request_id => @info_request.id
          expect(response).to redirect_to(
            admin_request_path(assigns[:censor_rule].info_request)
          )
        end
      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          post :create, :censor_rule => @censor_rule_params,
                        :request_id => @info_request.id
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          post :create, :censor_rule => @censor_rule_params,
                        :request_id => @info_request.id
          expect(response).to render_template('new')
        end

      end
    end

    context 'user_id param' do

      before(:each) do
        @user = FactoryGirl.create(:user)
        @censor_rule_params = FactoryGirl.attributes_for(:user_censor_rule, :user => @user)
        # last_edit_editor gets set in the controller
        @censor_rule_params.delete(:last_edit_editor)
      end

      def create_censor_rule
        post :create, :user_id => @user.id,
                      :censor_rule => @censor_rule_params
      end

      it 'sets the last_edit_editor to the current admin' do
        create_censor_rule
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'finds a user if the user_id param is supplied' do
        create_censor_rule
        expect(assigns[:censor_user]).to eq(@user)
      end

      it 'associates the user with the new censor rule' do
        create_censor_rule
        expect(assigns[:censor_rule].user).to eq(@user)
      end

      it 'sets the URL for the form to POST to' do
        create_censor_rule
        expect(assigns[:form_url]).to eq(admin_user_censor_rules_path(@user))
      end

      context 'successfully saving the censor rule' do
        it 'purges the cache for the info request' do
          expect(User).to receive(:find) { @user }
          censor_rules = double
          allow(@user).to receive(:censor_rules) { censor_rules }
          censor_rule = FactoryGirl.build(:user_censor_rule, :user => @user)
          allow(censor_rules).to receive(:build) { censor_rule }

          expect(censor_rule.user).to receive(:expire_requests)
          create_censor_rule
        end

        it 'redirects to the associated info request' do
          create_censor_rule
          expect(response).to redirect_to(
            admin_user_path(assigns[:censor_rule].user)
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          post :create, :censor_rule => @censor_rule_params,
                        :user_id => @user.id
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          post :create, :censor_rule => @censor_rule_params,
                        :user_id => @user.id
          expect(response).to render_template('new')
        end

      end

    end

    context 'body_id param' do

      before(:each) do
        @censor_rule_params = FactoryGirl.attributes_for(:public_body_censor_rule)
        # last_edit_editor gets set in the controller
        @censor_rule_params.delete(:last_edit_editor)
        @public_body = FactoryGirl.create(:public_body)
        post :create, :body_id => @public_body.id,
                      :censor_rule => @censor_rule_params
      end

      it 'sets the last_edit_editor to the current admin' do
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'finds a public body if the body_id param is supplied' do
        expect(assigns[:public_body]).to eq(@public_body)
      end

      it 'associates the public body with the new censor rule' do
        expect(assigns[:censor_rule].public_body).to eq(@public_body)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_body_censor_rules_path(@public_body))
      end

      context 'successfully saving the censor rule' do

        it 'persists the censor rule' do
          post :create, :censor_rule => @censor_rule_params,
                        :body_id => @public_body.id
          expect(assigns[:censor_rule]).to be_persisted
        end

        it 'confirms the censor rule is created' do
          post :create, :censor_rule => @censor_rule_params,
                        :body_id => @public_body.id
          msg = 'Censor rule was successfully created.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'redirects to the associated public body' do
          post :create, :censor_rule => @censor_rule_params,
                        :body_id => @public_body.id
          expect(response).to redirect_to(
            admin_body_path(assigns[:censor_rule].public_body)
          )
        end
      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          post :create, :censor_rule => @censor_rule_params,
                        :body_id => @public_body.id
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          post :create, :censor_rule => @censor_rule_params,
                        :body_id => @public_body.id
          expect(response).to render_template('new')
        end

      end
    end

  end

  describe 'GET edit' do

    context 'a CensorRule with an associated InfoRequest' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:info_request_censor_rule)
      end

      it 'returns a successful response' do
        get :edit, :id => @censor_rule.id
        expect(response).to be_success
      end

      it 'renders the correct template' do
        get :edit, :id => @censor_rule.id
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

    end

    context 'a CensorRule with an associated User' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:user_censor_rule)
      end

      it 'returns a successful response' do
        get :edit, :id => @censor_rule.id
        expect(response).to be_success
      end

      it 'renders the correct template' do
        get :edit, :id => @censor_rule.id
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

    end

    context 'a CensorRule with an associated PublicBody' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:public_body_censor_rule)
      end

      it 'returns a successful response' do
        get :edit, :id => @censor_rule.id
        expect(response).to be_success
      end

      it 'renders the correct template' do
        get :edit, :id => @censor_rule.id
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

    end

    context 'a global rule' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:global_censor_rule)
      end

      it 'returns a successful response' do
        get :edit, :id => @censor_rule.id
        expect(response).to be_success
      end

      it 'renders the correct template' do
        get :edit, :id => @censor_rule.id
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

    end

  end

  describe 'PUT update' do

    context 'a global censor rule' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:global_censor_rule)
      end

      it 'finds the correct censor rule to edit' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do

        it 'updates the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'redirects to the censor rule index' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to redirect_to(admin_censor_rules_path)
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to render_template('edit')
        end

      end

    end

    context 'a CensorRule with an associated InfoRequest' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:info_request_censor_rule)
      end

      it 'finds the correct censor rule to edit' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do

        it 'updates the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'purges the cache for the info request' do
          info_request = FactoryGirl.create(:info_request)
          allow(CensorRule).to receive(:find).and_return(@censor_rule)
          allow(@censor_rule).to receive(:info_request).and_return(info_request)
          expect(info_request).to receive(:expire)

          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
        end

        it 'redirects to the associated info request' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to redirect_to(
            admin_request_path(assigns[:censor_rule].info_request)
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to render_template('edit')
        end

      end

    end

    context 'a CensorRule with an associated User' do
      before(:each) do
        @censor_rule = FactoryGirl.create(:user_censor_rule)
      end

      it 'finds the correct censor rule to edit' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do
        it 'updates the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'purges the cache for the info request' do
          expect(CensorRule).to receive(:find) { @censor_rule }
          expect(@censor_rule.user).to receive(:expire_requests)

          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
        end

        it 'redirects to the associated info request' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to redirect_to(
            admin_user_path(assigns[:censor_rule].user)
          )
        end
      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to render_template('edit')
        end

      end

    end

    context 'a CensorRule with an associated PublicBody' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:public_body_censor_rule)
      end

      it 'finds the correct censor rule to edit' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, :id => @censor_rule.id,
          :censor_rule => { :text => 'different text' }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do

        it 'updates the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'redirects to the associated public body' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to redirect_to(
            admin_body_path(assigns[:censor_rule].public_body)
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }
          @censor_rule.reload
          expect(@censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, :id => @censor_rule.id,
            :censor_rule => { :text => 'different text' }

          expect(response).to render_template('edit')
        end

      end

    end

  end

  describe 'DELETE destroy' do

    context 'a global CensorRule' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:global_censor_rule)
      end

      it 'finds the correct censor rule to destroy' do
        delete :destroy, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, :id => @censor_rule.id
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the censor rules index' do
        delete :destroy, :id => @censor_rule.id
        expect(response).to redirect_to(admin_censor_rules_path)
      end

    end

    context 'a CensorRule with an associated InfoRequest' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:info_request_censor_rule)
      end

      it 'finds the correct censor rule to destroy' do
        delete :destroy, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, :id => @censor_rule.id
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'purges the cache for the info request' do
        expect(CensorRule).to receive(:find) { @censor_rule }
        expect(@censor_rule.info_request).to receive(:expire)
        delete :destroy, :id => @censor_rule.id
      end

      it 'redirects to the associated info request' do
        delete :destroy, :id => @censor_rule.id
        expect(response).to redirect_to(admin_request_path(@censor_rule.info_request))
      end

    end

    context 'a CensorRule with an associated User' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:user_censor_rule)
      end

      it 'finds the correct censor rule to destroy' do
        delete :destroy, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, :id => @censor_rule.id
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'purges the cache for the user' do
        expect(CensorRule).to receive(:find) { @censor_rule }
        expect(@censor_rule.user).to receive(:expire_requests)
        delete :destroy, :id => @censor_rule.id
      end

      it 'redirects to the associated info request' do
        delete :destroy, :id => @censor_rule.id
        expect(response).to redirect_to(admin_user_path(@censor_rule.user))
      end

    end

    context 'a CensorRule with an associated PublicBody' do

      before(:each) do
        @censor_rule = FactoryGirl.create(:public_body_censor_rule)
      end

      it 'finds the correct censor rule to destroy' do
        delete :destroy, :id => @censor_rule.id
        expect(assigns[:censor_rule]).to eq(@censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, :id => @censor_rule.id
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the associated public body' do
        delete :destroy, :id => @censor_rule.id
        expect(response).to redirect_to(admin_body_path(@censor_rule.public_body))
      end

    end

  end

end

describe AdminCensorRuleController, "when making censor rules from the admin interface" do
  render_views
  before { basic_auth_login @request }

  it "should create a censor rule and purge the corresponding request from varnish" do
    ir = info_requests(:fancy_dog_request)
    post :create, :request_id => ir.id,
                  :censor_rule => {
                    :text => "meat",
                    :replacement => "tofu",
                    :last_edit_comment => "none"
                  }
    expect(PurgeRequest.all.first.model_id).to eq(ir.id)
  end

end
