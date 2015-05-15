# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'request/show' do

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
                                                :user_name => @mock_user.name,
                                                :is_external? => false,
                                                :calculate_status => 'waiting_response',
                                                :date_response_required_by => Date.today,
                                                :prominence => 'normal',
                                                :comments_allowed? => true,
                                                :all_can_view? => true,
                                                :url_title => 'test_request')
    end

    def request_page
        assign :info_request, @mock_request
        assign :info_request_events, []
        assign :status, @mock_request.calculate_status
        render
    end

    describe 'when a status update has been requested' do

        before do
            assign :update_status, true
        end

        it 'should show the first form for describing the state of the request' do
            request_page
            response.should have_selector("div.describe_state_form#describe_state_form_1")
        end

    end

    describe 'when it is awaiting a description' do

        before do
            @mock_request.stub!(:awaiting_description).and_return(true)
        end

        it 'should show the first form for describing the state of the request' do
            request_page
            response.should have_selector("div.describe_state_form#describe_state_form_1")
        end

        it 'should show the second form for describing the state of the request' do
            request_page
            response.should have_selector("div.describe_state_form#describe_state_form_2")
        end

    end

    describe 'when the user is the request owner' do

        before do
            assign :is_owning_user, true
        end

        describe 'when the request status is "waiting clarification"' do

            before do
                @mock_request.stub!(:calculate_status).and_return('waiting_clarification')
            end

            describe 'when there is a last response' do

                before do
                    @mock_response = mock_model(IncomingMessage)
                    @mock_request.stub!(:get_last_public_response).and_return(@mock_response)
                end


                it 'should show a link to follow up the last response with clarification' do
                    request_page
                    expected_url = "/en/request/#{@mock_request.id}/response/#{@mock_response.id}#followup"
                    response.should have_selector("a", :href => expected_url, :content => 'send a follow up message')
                end

            end

            describe 'when there is no last response' do

                before do
                    @mock_request.stub!(:get_last_public_response).and_return(nil)
                end


                it 'should show a link to follow up the request without reference to a specific response' do
                    request_page
                    expected_url = "/en/request/#{@mock_request.id}/response#followup"
                    response.should have_selector("a", :href => expected_url, :content => 'send a follow up message')
                end
            end
        end

    end
end
