require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'when viewing an information request' do 
    
    before do 
        @mock_body = mock_model(PublicBody, :name => 'test body',
                                            :url_name => 'test_body',
                                            :is_school? => false)
        @mock_user = mock_model(User, :name => 'test user',
                                      :url_name => 'test_user',
                                      :profile_photo => nil)
        @mock_request = mock_model(InfoRequest, :title => 'test request',
                                                :awaiting_description => false, 
                                                :law_used_with_a => 'A Freedom of Information request',
                                                :law_used_full => 'Freedom of Information',
                                                :public_body => @mock_body,
                                                :user => @mock_user, 
                                                :calculate_status => 'waiting_response', 
                                                :date_response_required_by => Date.today,
                                                :prominence => 'normal')
    end
    
    def request_page
        assigns[:info_request] = @mock_request
        assigns[:info_request_events] = []
        assigns[:status] = @mock_request.calculate_status
        template.stub!(:render_partial)
        render 'request/show'
    end
    
    it 'should show the sidebar' do 
        template.should_receive(:render_partial).with(:partial => 'sidebar', :locals => {})
        request_page
    end
    
    it 'should show the actions people can take' do
        template.should_receive(:render_partial).with(:partial => 'after_actions', :locals => {})
        request_page
    end
    
    describe 'when a status update has been requested' do 
        
        before do 
            assigns[:update_status] = true
        end
        
        it 'should show the first form for describing the state of the request' do
            request_page
            response.should have_tag("div.describe_state_form#describe_state_form_1")
        end    
        
    end
    
    describe 'when it is awaiting a description' do 
    
        before do 
            @mock_request.stub!(:awaiting_description).and_return(true)
        end
        
        it 'should show the first form for describing the state of the request' do
            request_page
            response.should have_tag("div.describe_state_form#describe_state_form_1")
        end
        
        it 'should show the second form for describing the state of the request' do 
            request_page
            response.should have_tag("div.describe_state_form#describe_state_form_2")
        end
    
    end
    
    describe 'when the user is the request owner' do 
    
        before do 
            assigns[:is_owning_user] = true
        end
        
        describe 'when the request status is "waiting clarification"' do 
    
            before do 
                @mock_request.stub!(:calculate_status).and_return('waiting_clarification')
            end
        
            describe 'when there is a last response' do 
            
                before do
                    @mock_response = mock_model(IncomingMessage)
                    @mock_request.stub!(:get_last_response).and_return(@mock_response)
                    @old_filters = ActionController::Routing::Routes.filters
                    ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
                end
                after do
                    ActionController::Routing::Routes.filters = @old_filters
                end

            
                it 'should show a link to follow up the last response with clarification' do 
                    request_page
                    expected_url = "http://test.host/request/#{@mock_request.id}/response/#{@mock_response.id}#followup"
                    response.should have_tag("a[href=#{expected_url}]", :text => 'send a follow up message')
                end
            
            end
    
            describe 'when there is no last response' do
        
                before do 
                    @mock_request.stub!(:get_last_response).and_return(nil)
                    @old_filters = ActionController::Routing::Routes.filters
                    ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
                end
                after do
                    ActionController::Routing::Routes.filters = @old_filters
                end

            
                it 'should show a link to follow up the request without reference to a specific response' do 
                    request_page
                    expected_url = "http://test.host/request/#{@mock_request.id}/response#followup"
                    response.should have_tag("a[href=#{expected_url}]", :text => 'send a follow up message')
                end
            end
        end
    
    end
end
