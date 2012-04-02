require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LinkToHelper do 
    
    include LinkToHelper
    
    describe 'when creating a url for a request' do 
        
        before do
            @mock_request = mock_model(InfoRequest, :url_title => 'test_title')
            @old_filters = ActionController::Routing::Routes.filters
            ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
        end
        after do
            ActionController::Routing::Routes.filters = @old_filters
        end

        
        it 'should return a path like /request/test_title' do 
            request_url(@mock_request).should == '/request/test_title'
        end
        
        it 'should return a path including any extra parameters passed' do 
            request_url(@mock_request, {:update_status => 1}).should == '/request/test_title?update_status=1'
        end
        
    end

    describe "when appending something to a URL" do
        it 'should append to things without query strings' do
            main_url('/a', '.json').should == 'http://test.host/a.json'
        end
        it 'should append to things with query strings' do
            main_url('/a?z=1', '.json').should == 'http://test.host/a.json?z=1'
        end
        it 'should fail silently with invalid URLs' do
            main_url('/a?z=9%', '.json').should == 'http://test.host/a?z=9%'
        end
    end
    
end
