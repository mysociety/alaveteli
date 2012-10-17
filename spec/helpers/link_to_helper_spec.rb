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

    describe 'when displaying a user admin link for a request' do

        it 'should return the text "An anonymous user (external)" in the case where there is no external username' do
            info_request = mock_model(InfoRequest, :external_user_name => nil,
                                                   :is_external? => true)
            user_admin_link_for_request(info_request).should == 'Anonymous user (external)'
        end

    end

    describe 'admin_url' do
        context 'with no ADMIN_BASE_URL set' do
            it 'should prepend the admin general index path to a simple string' do
                admin_url('unclassified').should == 'http://test.host/en/admin/unclassified'
            end

            it 'should prepend the admin general index path to a deeper URL' do
                admin_url('request/show/123').should == 'http://test.host/en/admin/request/show/123'
            end
        end

        context 'with ADMIN_BASE_URL set' do
            before(:each) do
                Configuration::should_receive(:admin_base_url).and_return('https://www.example.com/secure/alaveteli-admin/')
            end

            it 'should prepend the admin base URL to a simple string' do
                admin_url('unclassified').should == 'https://www.example.com/secure/alaveteli-admin/unclassified'
            end

            it 'should prepend the admin base URL to a deeper URL' do
                admin_url('request/show/123').should == 'https://www.example.com/secure/alaveteli-admin/request/show/123'
            end
        end
    end
end
