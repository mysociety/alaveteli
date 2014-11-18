require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCensorRuleController do

    describe 'GET new' do

        it 'returns a successful response' do
            get :new
            expect(response).to be_success
        end

        it 'renders the correct template' do
            get :new
            expect(response).to render_template('new')
        end

        context 'info_request_id param' do

            it 'finds an info request if the info_request_id param is supplied' do
                info_request = FactoryGirl.create(:info_request)
                get :new, :info_request_id => info_request.id
                expect(assigns[:info_request]).to eq(info_request)
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

            it 'does not find a user if no user_id param is supplied' do
                get :new
                expect(assigns[:censor_user]).to be_nil
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
