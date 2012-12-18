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
                                                :url_title => 'test_request')
        assign :info_request, @mock_request
    end

    def do_render
        render :partial => 'request/after_actions'
    end

    def expect_owner_div
        do_render
        response.should have_selector('div#owner_actions'){ yield }
    end

    def expect_anyone_div
        do_render
        response.should have_selector('div#anyone_actions'){ yield }
    end

    def expect_owner_link(text)
        expect_owner_div{ with_tag('a', :content => text) }
    end

    def expect_no_owner_link(text)
        expect_owner_div{ without_tag('a', :content => text) }
    end

    def expect_anyone_link(text)
        expect_anyone_div{ with_tag('a', :content => text) }
    end

    def expect_no_anyone_link(text)
        expect_anyone_div{ without_tag('a', :content => text) }
    end

    describe 'if the request is old and unclassified' do

        before do
            assign :old_unclassified, true
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
            assign :old_unclassified, false
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

end
