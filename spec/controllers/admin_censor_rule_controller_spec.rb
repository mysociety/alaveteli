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
