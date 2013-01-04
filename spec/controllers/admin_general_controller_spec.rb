require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminGeneralController do

    describe "when viewing front page of admin interface" do

        render_views
        before { basic_auth_login @request }

        it "should render the front page" do
            get :index, :suppress_redirect => 1
            response.should render_template('index')
        end

        it "should redirect to include trailing slash" do
            get :index
            response.should redirect_to(:controller => 'admin_general',
                                        :action => 'index')
        end

    end

    describe 'when viewing the timeline' do

        it 'should assign an array of events in order of descending date to the view' do
            get :timeline, :all => 1
            previous_event = nil
            previous_event_at = nil
            assigns[:events].each do |event, event_at|
                if previous_event
                    (event_at <= previous_event_at).should be_true
                end
                previous_event = event
                previous_event_at = event_at
            end
        end

    end
end
