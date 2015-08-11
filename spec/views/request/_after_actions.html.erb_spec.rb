# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'when displaying actions that can be taken with regard to a request' do

    before do
        @mock_body = mock_model(PublicBody, :name => 'test public body',
                                            :url_name => 'test_public_body')
        @mock_user = mock_model(User, :name => 'test user',
                                      :url_name => 'test_user')
        @mock_request = mock_model(InfoRequest, :title => 'test request',
                                                :user => @mock_user,
                                                :user_name => @mock_user.name,
                                                :is_external? => false,
                                                :public_body => @mock_body,
                                                :comments_allowed? => true,
                                                :url_title => 'test_request',
                                                :all_can_view? => true)
        assign :info_request, @mock_request
    end

    describe 'if the request is old and unclassified' do

        before do
            assign :old_unclassified, true
        end

        it 'should not display a link for the request owner to update the status of the request' do
            render :partial => 'request/after_actions'
            expect(response.body).to have_css('div#owner_actions') do |div|
                expect(div).not_to have_css('a', :text => 'Update the status of this request')
            end
        end

        it 'should display a link for anyone to update the status of the request' do
            render :partial => 'request/after_actions'
            expect(response.body).to have_css('div#anyone_actions') do |div|
                expect(div).to have_css('a', :text => 'Update the status of this request')
            end
        end

    end

    describe 'if the request is not old and unclassified' do

        before do
            assign :old_unclassified, false
        end

        it 'should display a link for the request owner to update the status of the request' do
            render :partial => 'request/after_actions'
            expect(response.body).to have_css('div#owner_actions') do |div|
                expect(div).to have_css('a', :text => 'Update the status of this request')
            end
        end

        it 'should not display a link for anyone to update the status of the request' do
            render :partial => 'request/after_actions'
            expect(response.body).to have_css('div#anyone_actions') do |div|
                expect(div).not_to have_css('a', :text => 'Update the status of this request')
            end
        end

    end

    it 'should display a link for the request owner to request a review' do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('div#owner_actions') do |div|
            expect(div).to have_css('a', :text => 'Request an internal review')
        end
    end


    it 'should display the link to download the entire request' do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('div#anyone_actions') do |div|
            expect(div).to have_css('a', :text => 'Download a zip file of all correspondence')
        end
    end

end
