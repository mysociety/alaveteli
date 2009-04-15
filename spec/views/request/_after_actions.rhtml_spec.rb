require File.dirname(__FILE__) + '/../../spec_helper'

describe 'when displaying actions that can be taken with regard to a request' do 
    
    before do 
        @mock_body = mock_model(PublicBody, :name => 'test public body', 
                                            :url_name => 'test_public_body')
        @mock_user = mock_model(User, :name => 'test user', 
                                      :url_name => 'test_user')
        @mock_request = mock_model(InfoRequest, :title => 'test request', 
                                                :user => @mock_user, 
                                                :public_body => @mock_body, 
                                                :url_title => 'test_request')
        assigns[:info_request] = @mock_request
    end
  
    def do_render
        render :partial => 'request/after_actions'
    end
    
    def expect_owner_div
        do_render
        response.should have_tag('div#owner_actions'){ yield }
    end
    
    def expect_anyone_div
        do_render
        response.should have_tag('div#anyone_actions'){ yield }
    end
    
    def expect_owner_link(text)
        expect_owner_div{ with_tag('a', :text => text) }
    end
    
    def expect_no_owner_link(text)
        expect_owner_div{ without_tag('a', :text => text) }
    end
    
    def expect_anyone_link(text)
        expect_anyone_div{ with_tag('a', :text => text) }
    end
    
    def expect_no_anyone_link(text)
        expect_anyone_div{ without_tag('a', :text => text) }
    end
    
    describe 'if the request is old and unclassified' do 
    
        before do 
            assigns[:old_unclassified] = true
        end
        
        it 'should not display a link for the request owner to update the status of the request' do 
            expect_no_owner_link('Update the status of this request')
        end
        
        it 'should display a link for anyone to update the status of the request' do 
            expect_anyone_link('Update the status of this request')
        end
        
    end
    
    describe 'if the request is not old and unclassified' do 
        
        before do 
            assigns[:old_unclassified] = false
        end
        
        it 'should display a link for the request owner to update the status of the request' do 
            expect_owner_link('Update the status of this request')
        end
        
        it 'should not display a link for anyone to update the status of the request' do 
            expect_no_anyone_link('Update the status of this request')
        end
        
    end

    it 'should display a link for the request owner to request a review' do
        expect_owner_link('Request an internal review')
    end
    
    describe 'when there is no last response' do
        
        before do 
            assigns[:last_response] = nil
        end
    
        it 'should display a link for the request owner to send a follow up' do
            expect_owner_link('Send follow up to test public body')
        end
    
    end
    
    describe 'when there is a last response' do
        
        before do 
            assigns[:last_response] = mock_model(IncomingMessage, 
                                                 :valid_to_reply_to? => false)
        end
    
        it 'should display a link for the request owner to reply to the last response' do
            expect_owner_link('Reply to test public body')
        end
    
    end
    
end