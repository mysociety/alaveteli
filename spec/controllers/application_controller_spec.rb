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
        config = MySociety::Config.load_default()
        config['GAZE_URL'] = 'http://denmark.com'
        FakeWeb.register_uri(:get, %r|denmark.com|, :body => "DK")
        country = self.controller.send :country_from_ip
        country.should == "DK"
    end
    it "should fail silently if the country_from_ip domain doesn't exist" do
        config = MySociety::Config.load_default()
        config['GAZE_URL'] = 'http://12123sdf14qsd.com'
        country = self.controller.send :country_from_ip
        country.should == config['ISO_COUNTRY_CODE']
    end
    it "should fail silently if the country_from_ip service doesn't exist" do
        config = MySociety::Config.load_default()
        config['GAZE_URL'] = 'http://www.google.com'
        country = self.controller.send :country_from_ip
        country.should == config['ISO_COUNTRY_CODE']
    end
    it "should fail silently if the country_from_ip service returns an error" do
        FakeWeb.register_uri(:get, %r|500.com|, :body => "Error", :status => ["500", "Error"])
        config = MySociety::Config.load_default()
        config['GAZE_URL'] = 'http://500.com'
        country = self.controller.send :country_from_ip
        country.should == config['ISO_COUNTRY_CODE']
    end
end

describe ApplicationController, "when caching fragments" do
    it "should not fail with long filenames" do
        long_name = "blahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblah.txt"
        path = self.controller.send(:foi_fragment_cache_path, long_name)
        self.controller.send(:foi_fragment_cache_write, path, "whassap")
    end

end

