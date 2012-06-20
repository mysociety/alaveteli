# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ServicesController, "when using web services" do
    integrate_views
  
    it "should show no alaveteli message when in the deployed country" do
        config = MySociety::Config.load_default()
        config['ISO_COUNTRY_CODE'] = "DE"
        controller.stub!(:country_from_ip).and_return('DE')
        get :other_country_message
        response.body.should == ""
    end

    it "should show an alaveteli message when not in the deployed country and in a country with no FOI website" do
        config = MySociety::Config.load_default()
        config['ISO_COUNTRY_CODE'] = "DE"
        controller.stub!(:country_from_ip).and_return('ZZ')
        get :other_country_message
        response.body.should match(/outside Deutschland/)
    end

    it "should show link to other FOI website when not in the deployed country" do
        config = MySociety::Config.load_default()
        config['ISO_COUNTRY_CODE'] = "ZZ"
        controller.stub!(:country_from_ip).and_return('ES')
        request.env['HTTP_ACCEPT_LANGUAGE'] = "es"
        get :other_country_message
        response.body.should match(/Puede hacer solicitudes de información en España/)
    end


end
