require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LinkToHelper do

    include LinkToHelper

    describe 'when creating a url for a request' do

        before do
            @mock_request = mock_model(InfoRequest, :url_title => 'test_title')
        end

        it 'should return a path like /request/test_title' do
            request_path(@mock_request).should == '/request/test_title'
        end

        it 'should return a path including any extra parameters passed' do
            request_path(@mock_request, {:update_status => 1}).should == '/request/test_title?update_status=1'
        end

    end

    describe 'when displaying a user admin link for a request' do

        it 'should return the text "An anonymous user (external)" in the case where there is no external username' do
            info_request = mock_model(InfoRequest, :external_user_name => nil,
                                                   :is_external? => true)
            user_admin_link_for_request(info_request).should == 'Anonymous user (external)'
        end

    end

    describe 'simple_date' do
        it 'should respect time zones' do
            Time.use_zone('Australia/Sydney') do
                simple_date(Time.utc(2012, 11, 07, 21, 30, 26)).should == 'November 08, 2012'
            end
        end

        it 'should handle Date objects' do
            simple_date(Date.new(2012, 11, 21)).should == 'November 21, 2012'
        end
    end
end
