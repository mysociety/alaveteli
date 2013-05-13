# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When errors occur" do

    def set_consider_all_requests_local(value)
        @requests_local = Rails.application.config.consider_all_requests_local
        Rails.application.config.consider_all_requests_local = value
    end

    def restore_consider_all_requests_local
        Rails.application.config.consider_all_requests_local = @requests_local
    end

    before(:each) do
        # This should happen automatically before each test but doesn't with these integration
        # tests for some reason.
        ActionMailer::Base.deliveries = []
    end

    after(:each) do
        restore_consider_all_requests_local
    end

    context 'when considering all requests local (by default all in development)' do

        before(:each) { set_consider_all_requests_local(true) }

        it 'should show a full trace for general errors' do
            InfoRequest.stub!(:find_by_url_title!).and_raise("An example error")
            get("/request/example")
            response.body.should have_selector('div[id=traces]')
            response.body.should match('An example error')
        end

    end

    context 'when not considering all requests local' do

        before(:each) { set_consider_all_requests_local(false) }

        it "should render a 404 for unrouteable URLs using the general/exception_caught template" do
            get("/frobsnasm")
            response.should render_template('general/exception_caught')
            response.code.should == "404"
        end

        it "should render a 404 for users or bodies that don't exist using the general/exception_caught
            template" do
            ['/user/wobsnasm', '/body/wobsnasm'].each do |non_existent_url|
                get(non_existent_url)
                response.should render_template('general/exception_caught')
                response.code.should == "404"
            end
        end

        it "should render a 500 for general errors using the general/exception_caught template" do
            InfoRequest.stub!(:find_by_url_title!).and_raise("An example error")
            get("/request/example")
            response.should render_template('general/exception_caught')
            response.body.should match('An example error')
            response.code.should == "500"
        end

        it 'should notify of a general error' do
            InfoRequest.stub!(:find_by_url_title!).and_raise("An example error")
            get("/request/example")
            deliveries = ActionMailer::Base.deliveries
            deliveries.size.should == 1
            mail = deliveries[0]
            mail.body.should =~ /An example error/
        end

        it 'should log a general error' do
            Rails.logger.should_receive(:fatal)
            InfoRequest.stub!(:find_by_url_title!).and_raise("An example error")
            get("/request/example")
        end

        it 'should assign the locale for the general/exception_caught template' do
            InfoRequest.stub!(:find_by_url_title!).and_raise("An example error")
            get("/es/request/example")
            response.should render_template('general/exception_caught')
            response.body.should match('Lo sentimos, hubo un problema procesando esta página')
            response.body.should match('An example error')
        end

        it "should render a 403 with text body for attempts at directory listing for attachments" do
            # make a fake cache
            foi_cache_path = File.expand_path(File.join(File.dirname(__FILE__), '../../cache'))
            FileUtils.mkdir_p(File.join(foi_cache_path, "views/en/request/101/101/response/1/attach/html/1"))
            get("/request/101/response/1/attach/html/1/" )
            response.body.should include("Directory listing not allowed")
            response.code.should == "403"
            get("/request/101/response/1/attach/html" )
            response.body.should include("Directory listing not allowed")
            response.code.should == "403"
        end

        context "in the admin interface" do

            it 'should show a full trace for general errors' do
                InfoRequest.stub!(:find).and_raise("An example error")
                get("/admin/request/show/333")
                response.body.should have_selector('div[id=traces]')
                response.body.should match('An example error')
            end

        end

    end

end
