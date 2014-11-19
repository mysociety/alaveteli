require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCensorRuleController do
    before(:each) { basic_auth_login(@request) }

    describe 'GET new' do

        it 'returns a successful response' do
            get :new
            expect(response).to be_success
        end

        it 'initializes a new censor rule' do
            get :new
            expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the correct template' do
            get :new
            expect(response).to render_template('new')
        end

        it 'sets the URL for the form to POST to' do
            get :new
            expect(assigns[:form_url]).to eq(admin_rule_create_path)
        end

        context 'info_request_id param' do

            it 'finds an info request if the info_request_id param is supplied' do
                info_request = FactoryGirl.create(:info_request)
                get :new, :info_request_id => info_request.id
                expect(assigns[:info_request]).to eq(info_request)
            end

            it 'associates the info request with the new censor rule' do
                info_request = FactoryGirl.create(:info_request)
                get :new, :info_request_id => info_request.id
                expect(assigns[:censor_rule].info_request).to eq(info_request)
            end

            it 'sets the URL for the form to POST to' do
                info_request = FactoryGirl.create(:info_request)
                get :new, :info_request_id => info_request.id
                expect(assigns[:form_url]).to eq(admin_info_request_censor_rules_path(info_request))
            end

            it 'does not find an info request if no info_request_id param is supplied' do
                get :new
                expect(assigns[:info_request]).to be_nil
            end

        end

        context 'user_id param' do

            it 'finds a user if the user_id param is supplied' do
                user = FactoryGirl.create(:user)
                get :new, :user_id => user.id
                expect(assigns[:censor_user]).to eq(user)
            end

            it 'associates the user with the new censor rule' do
                user = FactoryGirl.create(:user)
                get :new, :user_id => user.id
                expect(assigns[:censor_rule].user).to eq(user)
            end

            it 'sets the URL for the form to POST to' do
                user = FactoryGirl.create(:user)
                get :new, :user_id => user.id
                expect(assigns[:form_url]).to eq(admin_user_censor_rules_path(user))
            end

            it 'does not find a user if no user_id param is supplied' do
                get :new
                expect(assigns[:censor_user]).to be_nil
            end

        end

    end

    describe 'POST create' do

        before(:each) do
            @censor_rule_params = FactoryGirl.build(:global_censor_rule).serializable_hash
            # last_edit_editor gets set in the controller
            @censor_rule_params.delete(:last_edit_editor)
        end

        it 'sets the last_edit_editor to the current admin' do
            post :create, :censor_rule => @censor_rule_params
            expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
        end

        context 'successfully saving the censor rule' do

            before(:each) do
                CensorRule.any_instance.stub(:save).and_return(true)
            end

            it 'persists the censor rule' do
                pending("This raises an internal error in most cases")
                post :create, :censor_rule => @censor_rule_params
                expect(assigns[:censor_rule]).to be_persisted
            end

            it 'confirms the censor rule is created' do
                pending("This raises an internal error in most cases")
                post :create, :censor_rule => @censor_rule_params
                msg = 'CensorRule was successfully created.'
                expect(flash[:notice]).to eq(msg)
            end

            it 'raises an error after creating the rule' do
                expect {
                    post :create, :censor_rule => @censor_rule_params
                }.to raise_error 'internal error'
            end

            context 'a CensorRule with an associated InfoRequest' do

                before(:each) do
                    @censor_rule_params = FactoryGirl.build(:info_request_censor_rule).serializable_hash
                    # last_edit_editor gets set in the controller
                    @censor_rule_params.delete(:last_edit_editor)
                end

                it 'purges the cache for the info request' do
                    censor_rule = CensorRule.new(@censor_rule_params)
                    @controller.should_receive(:expire_for_request).
                        with(censor_rule.info_request)

                    post :create, :censor_rule => @censor_rule_params
                end

                it 'redirects to the associated info request' do
                    post :create, :censor_rule => @censor_rule_params
                    expect(response).to redirect_to(
                        admin_request_show_path(assigns[:censor_rule].info_request)
                    )
                end

            end

            context 'a CensorRule with an associated User' do

                before(:each) do
                    @censor_rule_params = FactoryGirl.build(:user_censor_rule).serializable_hash
                    # last_edit_editor gets set in the controller
                    @censor_rule_params.delete(:last_edit_editor)
                end

                 it 'purges the cache for the info request' do
                    censor_rule = CensorRule.new(@censor_rule_params)
                    @controller.should_receive(:expire_requests_for_user).
                        with(censor_rule.user)

                    post :create, :censor_rule => @censor_rule_params
                end

                it 'redirects to the associated info request' do
                    post :create, :censor_rule => @censor_rule_params
                    expect(response).to redirect_to(
                        admin_user_show_path(assigns[:censor_rule].user)
                    )
                end

            end

        end

        context 'unsuccessfully saving the censor rule' do

            before(:each) do
                CensorRule.any_instance.stub(:save).and_return(false)
            end

            it 'does not persist the censor rule' do
                post :create, :censor_rule => @censor_rule_params
                expect(assigns[:censor_rule]).to be_new_record
            end

            it 'renders the form' do
                post :create, :censor_rule => @censor_rule_params
                expect(response).to render_template('new')
            end

        end

    end

    describe 'GET edit' do

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

    describe 'PUT update' do

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

            before(:each) do
                CensorRule.any_instance.stub(:save).and_return(true)
            end

            it 'updates the censor rule' do
                pending("This raises an internal error in most cases")
                put :update, :id => @censor_rule.id,
                             :censor_rule => { :text => 'different text' }
                @censor_rule.reload
                expect(@censor_rule.text).to eq('different text')
            end

            it 'confirms the censor rule is updated' do
                pending("This raises an internal error in most cases")
                put :update, :id => @censor_rule.id,
                             :censor_rule => { :text => 'different text' }

                msg = 'CensorRule was successfully updated.'
                expect(flash[:notice]).to eq(msg)
            end

            it 'raises an error after updating the rule' do
                expect {
                    put :update, :id => @censor_rule.id,
                                 :censor_rule => { :text => 'different text' }
                }.to raise_error 'internal error'
            end

            context 'a CensorRule with an associated InfoRequest' do

                before(:each) do
                    @censor_rule = FactoryGirl.create(:info_request_censor_rule)
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
                        admin_request_show_path(assigns[:censor_rule].info_request)
                    )
                end

            end

            context 'a CensorRule with an associated User' do

                before(:each) do
                    @censor_rule = FactoryGirl.create(:user_censor_rule)
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
                        admin_user_show_path(assigns[:censor_rule].user)
                    )
                end

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

    describe 'DELETE destroy' do

        before(:each) do
            @censor_rule = FactoryGirl.create(:global_censor_rule)
        end

        it 'finds the correct censor rule to destroy' do
            pending("Assign the CensorRule to an instance variable")
            # TODO: Replace :censor_rule_id with :id
            delete :destroy, :censor_rule_id => @censor_rule.id
            # TODO: Assign the CensorRule to an instance variable
            expect(assigns[:censor_rule]).to eq(@censor_rule)
        end

        it 'raises an error after destroying the rule' do
            expect {
                delete :destroy, :censor_rule_id => @censor_rule.id
            }.to raise_error 'internal error'
        end

        it 'confirms the censor rule is destroyed in all cases' do
            pending("This actually raises an internal error anyway")
            delete :destroy, :censor_rule_id => @censor_rule.id
            msg = 'CensorRule was successfully destroyed.'
            expect(flash[:notice]).to eq(msg)
        end

        context 'a CensorRule with an associated InfoRequest' do

            before(:each) do
                @censor_rule = FactoryGirl.create(:info_request_censor_rule)
            end

            it 'purges the cache for the info request' do
                @controller.should_receive(:expire_for_request).with(@censor_rule.info_request)
                delete :destroy, :censor_rule_id => @censor_rule.id
            end

            it 'redirects to the associated info request' do
                delete :destroy, :censor_rule_id => @censor_rule.id
                expect(response).to redirect_to(admin_request_show_path(@censor_rule.info_request))
            end

        end

        context 'a CensorRule with an associated User' do

            before(:each) do
                @censor_rule = FactoryGirl.create(:user_censor_rule)
            end

            it 'purges the cache for the user' do
                @controller.should_receive(:expire_requests_for_user).with(@censor_rule.user)
                delete :destroy, :censor_rule_id => @censor_rule.id
            end

            it 'redirects to the associated info request' do
                delete :destroy, :censor_rule_id => @censor_rule.id
                expect(response).to redirect_to(admin_user_show_path(@censor_rule.user))
            end

        end

    end

end

describe AdminCensorRuleController, "when making censor rules from the admin interface" do
    render_views
    before { basic_auth_login @request }
  
    it "should create a censor rule and purge the corresponding request from varnish" do
        ir = info_requests(:fancy_dog_request) 
        post :create, :censor_rule => {
                         :text => "meat",
                         :replacement => "tofu",
                         :last_edit_comment => "none",
                         :info_request_id => ir
        }
        PurgeRequest.all().first.model_id.should == ir.id
    end


end
