require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakeweb'

describe ApplicationController, "when accessing third party services" do
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
        FakeWeb.register_uri(:get, %r|.*|, :body => "Error", :status => ["500", "Error"])
        config = MySociety::Config.load_default()
        config['GAZE_URL'] = 'http://500.com'
        country = self.controller.send :country_from_ip
        country.should == config['ISO_COUNTRY_CODE']
    end
end

