# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCensorRuleController do
    before(:each) { basic_auth_login(@request) }

    describe 'GET new' do

        context 'request_id param' do

            before do
                @info_request = FactoryGirl.create(:info_request)
                get :new, :request_id => @info_request.id, :name_prefix => 'request_'
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
                get :new, :user_id => @user.id, :name_prefix => 'user_'
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

    end

    describe 'POST create' do

        context 'request_id param' do

            before(:each) do
                @censor_rule_params = FactoryGirl.build(:info_request_censor_rule).serializable_hash
                # last_edit_editor gets set in the controller
                @censor_rule_params.delete(:last_edit_editor)
                @info_request = FactoryGirl.create(:info_request)
                post :create, :request_id => @info_request.id,
                              :censor_rule => @censor_rule_params,
                              :name_prefix => 'request_'
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
                                  :request_id => @info_request.id,
                                  :name_prefix => 'request_'
                    expect(assigns[:censor_rule]).to be_persisted
                end

                it 'confirms the censor rule is created' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :request_id => @info_request.id,
                                  :name_prefix => 'request_'
                    msg = 'CensorRule was successfully created.'
                    expect(flash[:notice]).to eq(msg)
                end

                it 'purges the cache for the info request' do
                    @controller.should_receive(:expire_for_request).
                        with(@info_request)

                    post :create, :censor_rule => @censor_rule_params,
                                  :request_id => @info_request.id,
                                  :name_prefix => 'request_'
                end

                it 'redirects to the associated info request' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :request_id => @info_request.id,
                                  :name_prefix => 'request_'
                    expect(response).to redirect_to(
                        admin_request_path(assigns[:censor_rule].info_request)
                    )
                end
            end

            context 'unsuccessfully saving the censor rule' do

                before(:each) do
                    CensorRule.any_instance.stub(:save).and_return(false)
                end

                it 'does not persist the censor rule' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :request_id => @info_request.id,
                                  :name_prefix => 'request_'
                    expect(assigns[:censor_rule]).to be_new_record
                end

                it 'renders the form' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :request_id => @info_request.id,
                                  :name_prefix => 'request_'
                    expect(response).to render_template('new')
                end

            end
        end

        context 'user_id param' do

            before(:each) do
                @censor_rule_params = FactoryGirl.build(:user_censor_rule).serializable_hash
                # last_edit_editor gets set in the controller
                @censor_rule_params.delete(:last_edit_editor)
                @user = FactoryGirl.create(:user)
                post :create, :user_id => @user.id,
                              :censor_rule => @censor_rule_params,
                              :name_prefix => 'user_'
            end

            it 'sets the last_edit_editor to the current admin' do
                expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
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

            context 'successfully saving the censor rule' do

                 it 'purges the cache for the info request' do
                    censor_rule = CensorRule.new(@censor_rule_params)
                    @controller.should_receive(:expire_requests_for_user).
                        with(@user)

                    post :create, :censor_rule => @censor_rule_params,
                                  :user_id => @user.id,
                                  :name_prefix => 'user_'
                end

                it 'redirects to the associated info request' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :user_id => @user.id,
                                  :name_prefix => 'user_'
                    expect(response).to redirect_to(
                        admin_user_path(assigns[:censor_rule].user)
                    )
                end

            end

            context 'unsuccessfully saving the censor rule' do

                before(:each) do
                    CensorRule.any_instance.stub(:save).and_return(false)
                end

                it 'does not persist the censor rule' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :user_id => @user.id,
                                  :name_prefix => 'user_'
                    expect(assigns[:censor_rule]).to be_new_record
                end

                it 'renders the form' do
                    post :create, :censor_rule => @censor_rule_params,
                                  :user_id => @user.id,
                                  :name_prefix => 'user_'
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

        context 'when editing a global rule' do

            before(:each) do
                @censor_rule = FactoryGirl.create(:global_censor_rule)
            end

            it 'shows an error notice' do
                get :edit, :id => @censor_rule.id
                flash[:notice].should == 'Only user and request censor rules can be edited'
            end

            it 'redirects to the admin index' do
                get :edit, :id => @censor_rule.id
                expect(response).to redirect_to(admin_general_index_path)
            end

        end

    end

    describe 'PUT update' do

        context 'a global CensorRule' do

            before(:each) do
                @censor_rule = FactoryGirl.create(:global_censor_rule)
            end

            it 'shows an error notice' do
                get :edit, :id => @censor_rule.id
                flash[:notice].should == 'Only user and request censor rules can be edited'
            end

            it 'redirects to the admin index' do
                get :edit, :id => @censor_rule.id
                expect(response).to redirect_to(admin_general_index_path)
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
                    msg = 'CensorRule was successfully updated.'
                    expect(flash[:notice]).to eq(msg)
                end

                 it 'purges the cache for the info request' do
                    @controller.should_receive(:expire_for_request).
                        with(@censor_rule.info_request)

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
                    CensorRule.any_instance.stub(:save).and_return(false)
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
                    msg = 'CensorRule was successfully updated.'
                    expect(flash[:notice]).to eq(msg)
                end

                 it 'purges the cache for the info request' do
                    @controller.should_receive(:expire_requests_for_user).
                        with(@censor_rule.user)

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
                    CensorRule.any_instance.stub(:save).and_return(false)
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

            it 'shows an error notice' do
                get :edit, :id => @censor_rule.id
                flash[:notice].should == 'Only user and request censor rules can be edited'
            end

            it 'redirects to the admin index' do
                get :edit, :id => @censor_rule.id
                expect(response).to redirect_to(admin_general_index_path)
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
                msg = 'CensorRule was successfully destroyed.'
                expect(flash[:notice]).to eq(msg)
            end

            it 'purges the cache for the info request' do
                @controller.should_receive(:expire_for_request).with(@censor_rule.info_request)
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
                msg = 'CensorRule was successfully destroyed.'
                expect(flash[:notice]).to eq(msg)
            end

            it 'purges the cache for the user' do
                @controller.should_receive(:expire_requests_for_user).with(@censor_rule.user)
                delete :destroy, :id => @censor_rule.id
            end

            it 'redirects to the associated info request' do
                delete :destroy, :id => @censor_rule.id
                expect(response).to redirect_to(admin_user_path(@censor_rule.user))
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
                      :name_prefix => 'request_',
                      :censor_rule => {
                         :text => "meat",
                         :replacement => "tofu",
                         :last_edit_comment => "none"
        }
        PurgeRequest.all().first.model_id.should == ir.id
    end

end
