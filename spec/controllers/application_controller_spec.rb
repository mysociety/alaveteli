require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakeweb'

describe ApplicationController, "when accessing third party services" do

    before (:each) do
        FakeWeb.clean_registry
    end

    after (:each) do
        FakeWeb.clean_registry
    end

    it "should succeed if the service responds OK" do
        Configuration.stub!(:gaze_url).and_return('http://denmark.com')
        FakeWeb.register_uri(:get, %r|denmark.com|, :body => "DK")
        country = self.controller.send :country_from_ip
        country.should == "DK"
    end
    it "should fail silently if the country_from_ip domain doesn't exist" do
        Configuration.stub!(:gaze_url).and_return('http://12123sdf14qsd.com')
        country = self.controller.send :country_from_ip
        country.should == Configuration.iso_country_code
    end
    it "should fail silently if the country_from_ip service doesn't exist" do
        Configuration.stub!(:gaze_url).and_return('http://www.google.com')
        country = self.controller.send :country_from_ip
        country.should == Configuration.iso_country_code
    end
    it "should fail silently if the country_from_ip service returns an error" do
        FakeWeb.register_uri(:get, %r|500.com|, :body => "Error", :status => ["500", "Error"])
        Configuration.stub!(:gaze_url).and_return('http://500.com')
        country = self.controller.send :country_from_ip
        country.should == Configuration.iso_country_code
    end
end

describe ApplicationController, "when caching fragments" do

    it "should not fail with long filenames" do
        long_name = "blahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblah.txt"
        params = { :only_path => true,
                   :file_name => [long_name],
                   :controller => "request",
                   :action => "get_attachment_as_html",
                   :id => "132",
                   :incoming_message_id => "44",
                   :part => "2" }
        path = self.controller.send(:foi_fragment_cache_path, params)
        self.controller.send(:foi_fragment_cache_write, path, "whassap")
    end

end

