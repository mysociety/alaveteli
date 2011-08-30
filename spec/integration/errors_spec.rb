require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module TestCustomStates
    def self.included(base)
        base.extend(ClassMethods)
    end

    module ClassMethods 
        def theme_extra_states
            return ['crotchety']
        end
    end
end


describe "When rendering errors" do

    fixtures [ :info_requests,
               :info_request_events,
               :public_bodies,
               :public_body_translations,
               :users,
               :raw_emails,
               :outgoing_messages,
               :incoming_messages,
               :comments ]

    before(:each) do
        load_raw_emails_data(raw_emails)
        ActionController::Base.consider_all_requests_local = false
    end

    after(:each) do
         ActionController::Base.consider_all_requests_local = true
    end

    it "should render a 404 for unrouteable URLs" do
        get("/frobsnasm")
        response.code.should == "404"
        response.body.should include("The page doesn't exist")        
    end
    it "should render a 404 for users that don't exist" do
        get("/user/wobsnasm")
        response.code.should == "404"
    end
    it "should render a 404 for bodies that don't exist" do
        get("/body/wobsnasm")
        response.code.should == "404"
    end
    it "should render a 500 for general errors" do
        ir = info_requests(:naughty_chicken_request)
        InfoRequest.send(:include, TestCustomStates)
        InfoRequest.class_eval('@@custom_states_loaded = true')
        ir.set_described_state("crotchety")
        ir.save!
        InfoRequest.class_eval('@@custom_states_loaded = false')
        get("/request/#{ir.url_title}")
        response.code.should == "500"
    end
end

