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

    describe 'if the request is viewable by all' do

        it 'should display the link to download the entire request' do
            expect_anyone_link('Download a zip file of all correspondence')
        end
    end

    describe 'if the request is not viewable by all' do

        it 'should not  display the link to download the entire request' do
            @mock_request.stub!(:all_can_view?).and_return(false)
            expect_no_anyone_link('Download a zip file of all correspondence')
        end
    end

end
