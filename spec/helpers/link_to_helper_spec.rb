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

    describe 'when displaying a user link for a request' do

        context "for external requests" do
            before do
                @info_request = mock_model(InfoRequest, :external_user_name => nil,
                                                       :is_external? => true)
            end

            it 'should return the text "Anonymous user" with a link to the privacy help pages when there is no external username' do
                request_user_link(@info_request).should == '<a href="/help/privacy#anonymous">Anonymous user</a>'
            end

            it 'should return a link with an alternative text if requested' do
                request_user_link(@info_request, 'other text').should == '<a href="/help/privacy#anonymous">other text</a>'
            end

            it 'should display an absolute link if requested' do
                request_user_link_absolute(@info_request).should == '<a href="http://test.host/help/privacy#anonymous">Anonymous user</a>'
            end
        end

        context "for normal requests" do

            before do
                @info_request = FactoryGirl.build(:info_request)
            end

            it 'should display a relative link by default' do
                request_user_link(@info_request).should == '<a href="/user/example_user">Example User</a>'
            end

            it 'should display an absolute link if requested' do
                request_user_link_absolute(@info_request).should == '<a href="http://test.host/user/example_user">Example User</a>'
            end

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

        it 'formats a date in html by default' do
            time = Time.utc(2012, 11, 07, 21, 30, 26)
            self.should_receive(:simple_date_html).with(time)
            simple_date(time)
        end

        it 'formats a date in the specified format' do
            time = Time.utc(2012, 11, 07, 21, 30, 26)
            self.should_receive(:simple_date_text).with(time)
            simple_date(time, :format => :text)
        end

        it 'raises an argument error if given an unrecognized format' do
            time = Time.utc(2012, 11, 07, 21, 30, 26)
            expect { simple_date(time, :format => :unknown) }.to raise_error(ArgumentError)
        end

    end

    describe 'simple_date_html' do

        it 'formats a date in a time tag' do
            Time.use_zone('London') do
                time = Time.utc(2012, 11, 07, 21, 30, 26)
                expected = "<time datetime=\"2012-11-07T21:30:26+00:00\" title=\"2012-11-07 21:30:26 +0000\">November 07, 2012</time>"
                simple_date_html(time).should == expected
            end
        end

    end

    describe 'simple_date_text' do

        it 'should respect time zones' do
            Time.use_zone('Australia/Sydney') do
                simple_date_text(Time.utc(2012, 11, 07, 21, 30, 26)).should == 'November 08, 2012'
            end
        end

        it 'should handle Date objects' do
            simple_date_text(Date.new(2012, 11, 21)).should == 'November 21, 2012'
        end

    end

end
