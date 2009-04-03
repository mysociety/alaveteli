require File.dirname(__FILE__) + '/../spec_helper'

describe LinkToHelper do 
    
    include LinkToHelper
    
    describe 'when creating a url for a request' do 
        
        before do
            @mock_request = mock_model(InfoRequest, :url_title => 'test_title')
        end
        
        it 'should return a path like /request/test_title' do 
            request_url(@mock_request).should == '/request/test_title'
        end
        
        it 'should return a path including any extra parameters passed' do 
            request_url(@mock_request, {:update_status => 1}).should == '/request/test_title?update_status=1'
        end
        
    end
    
end