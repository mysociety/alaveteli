require File.dirname(__FILE__) + '/../../spec_helper'

describe 'when showing the form for describing the state of a request' do 
    
    def expect_radio_button(value)
        do_render
        response.should have_tag("input[type=radio][value=#{value}]")
    end
    
    def expect_no_radio_button(value)
        do_render
        response.should_not have_tag("input[type=radio][value=#{value}]")
    end

    def do_render
        render :partial => 'request/describe_state', :locals => {:id_suffix => '1'}
    end
    
    before do 
        @mock_user = mock_model(User, :name => 'test user', :url_name => 'test_user')
        @mock_request = mock_model(InfoRequest, :described_state => '', :user => @mock_user)
        assigns[:info_request] = @mock_request
    end
    
    describe 'if the user is a regular user' do
        
        before do 
            assigns[:is_owning_user] = false
        end
        
        it 'should not show the form' do 
            do_render
            response.should_not have_tag('form')
        end
        
        it 'should give a link to login' do 
            do_render
            response.should have_tag('a', :text => 'sign in')
        end
            
    end
    
    describe 'if showing the form to the user owning the request' do 
    
        before do 
            assigns[:is_owning_user] = true
        end
    
        describe 'when the request is not in internal review' do 
        
            before do 
                @mock_request.stub!(:described_state).and_return('waiting response')
            end    
    
            it 'should show a radio button to set the status to "waiting response"' do 
                expect_radio_button('waiting_response')
            end
        
            it 'should show a radio button to set the status to "waiting clarification"' do 
                expect_radio_button('waiting_clarification')
            end
            
            it 'should not show a radio button to set the status to "internal_review"' do 
                expect_no_radio_button('internal_review')
            end
        
        end
        
        describe 'when the user has asked to update the status of the request' do 
            
            before do 
                assigns[:update_status] = true
            end
            
            it 'should show a radio button to set the status to "internal_review"' do 
                expect_radio_button('internal_review')
            end

            it 'should show a radio button to set the status to "requires_admin"' do 
                expect_radio_button('requires_admin')
            end

            it 'should show a radio button to set the status to "user_withdrawn"' do 
                expect_radio_button('user_withdrawn')
            end
            
        end
    
        describe 'when the request is in internal review' do 

            before do 
                @mock_request.stub!(:described_state).and_return('internal_review')
            end
    
            it 'should show a radio button to set the status to "internal review"' do 
                expect_radio_button('internal_review')
            end
        
            it 'should show the text "The review has finished and overall:"' do 
                do_render
                response.should have_tag('p', :text => 'The review has finished and overall:')
            end
    
        end
        
        describe 'when request is awaiting a description and the user has not asked to update the status' do 
        end
    
        it 'should show a radio button to set the status to "gone postal"' do 
            expect_radio_button('gone_postal') 
        end
    
        it 'should show a radio button to set the status to "not held"' do 
            expect_radio_button('not_held') 
        end
    
        it 'should show a radio button to set the status to "partially successful"' do 
            expect_radio_button('partially_successful') 
        end
    
        it 'should show a radio button to set the status to "successful"' do 
            expect_radio_button('successful') 
        end
    
        it 'should show a radio button to set the status to "rejected"' do 
            expect_radio_button('rejected') 
        end
    
        it 'should show a radio button to set the status to "error_message"' do 
            expect_radio_button('error_message') 
        end
    
        it 'should not show a radio button to set the status to "requires_admin"' do 
            expect_no_radio_button('requires_admin') 
        end
        
        it 'should not show a radio button to set the status to "user_withdrawn"' do 
            expect_no_radio_button('user_withdrawn')
        end
        
    end
end