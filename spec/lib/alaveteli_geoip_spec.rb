# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AlaveteliGeoIP do

  describe '.country_code_from_ip' do

    it 'delegates to an instance of the class' do
      instance = double
      allow(AlaveteliGeoIP).to receive(:instance).and_return(instance)
      expect(instance).to receive(:country_code_from_ip).with('127.0.0.1')
      AlaveteliGeoIP.country_code_from_ip '127.0.0.1'
    end

  end

  describe '.instance' do

    it 'creates a new instance' do
      expect(AlaveteliGeoIP.instance).to be_instance_of(AlaveteliGeoIP)
    end

    it 'caches the instance' do
      expect(AlaveteliGeoIP.instance).to equal(AlaveteliGeoIP.instance)
    end

  end

  describe '.new' do

    it 'configures the instance with the configured country code' do
      expect(AlaveteliGeoIP.new.current_code).
        to eq(AlaveteliConfiguration::iso_country_code)
    end

    context 'if a database param is supplied' do

      it 'configures the instance with the database specified' do
        allow(File).to receive(:file?).
          with('/my/geoip/database').and_return(true)
        expect(GeoIP).to receive(:new).with('/my/geoip/database')
        AlaveteliGeoIP.new('/my/geoip/database')
      end

    end

    context 'if there is a geoip database configured and present' do

      it 'configures the instance with an instance of geoip' do
        allow(File).to receive(:file?).
          with(AlaveteliConfiguration::geoip_database).and_return(true)
        expect(GeoIP).to receive(:new).with(AlaveteliConfiguration::geoip_database)
        AlaveteliGeoIP.new
      end

    end

    context 'if there is only a Gaze URL configured' do

      it 'configures the instance with the Gaze URL' do
        allow(AlaveteliConfiguration).to receive(:geoip_database).and_return(nil)
        allow(AlaveteliConfiguration).to receive(:gaze_url).
          and_return('http://gaze.example.net')
        expect(AlaveteliGeoIP.new.gaze_url).
         to eq('http://gaze.example.net')
      end

    end

  end

  describe '#country_code_from_ip' do

    context 'when the Gaze service is configured and is in different states' do

      before(:each) do
        FakeWeb.clean_registry
        allow(AlaveteliConfiguration).to receive(:geoip_database).and_return ''
      end

      after(:each) do
        FakeWeb.clean_registry
      end

      it "returns the country code if the service returns one" do
        allow(AlaveteliConfiguration).to receive(:gaze_url).and_return('http://denmark.com')
        FakeWeb.register_uri(:get, %r|denmark.com|, :body => "DK")
        expect(AlaveteliGeoIP.new.country_code_from_ip('127.0.0.1')).to eq('DK')
      end

      it "returns the current code if the service domain doesn't exist" do
        allow(AlaveteliConfiguration).to receive(:gaze_url).and_return('http://12123sdf14qsd.com')
        instance = AlaveteliGeoIP.new
        expect(instance.country_code_from_ip('127.0.0.1'))
          .to eq(instance.current_code)
      end

      it "returns the current code if the service doesn't exist" do
        allow(AlaveteliConfiguration).to receive(:gaze_url).and_return('http://www.google.com')
        instance = AlaveteliGeoIP.new
        expect(instance.country_code_from_ip('127.0.0.1'))
          .to eq(instance.current_code)
      end

      it "returns the current code if the service isn't configured" do
        allow(AlaveteliConfiguration).to receive(:gaze_url).and_return('')
        instance = AlaveteliGeoIP.new
        expect(instance.country_code_from_ip('127.0.0.1'))
          .to eq(instance.current_code)
      end


      it "returns the current code and logs the error with url if the
           service returns an error" do
        FakeWeb.register_uri(:get, %r|500.com|, :body => "Error", :status => ["500", "Error"])
        allow(AlaveteliConfiguration).to receive(:gaze_url).and_return('http://500.com')
        expect(Rails.logger).to receive(:warn).with /500\.com.*500 Error/
        instance = AlaveteliGeoIP.new
        expect(instance.country_code_from_ip('127.0.0.1'))
          .to eq(instance.current_code)
      end

    end

    context 'when the geoip database is configured' do

      it 'returns the country code if the geoip object returns one' do
        CountryData = Struct.new(:country_code2)
        geoip = double('FakeGeoIP', :country => CountryData.new('XX'))
        instance = AlaveteliGeoIP.new
        allow(instance).to receive(:geoip).and_return(geoip)
        expect(instance.country_code_from_ip('127.0.0.1'))
          .to eq('XX')
      end

    end

  end

end
