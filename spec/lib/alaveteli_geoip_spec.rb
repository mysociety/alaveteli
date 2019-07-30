# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AlaveteliGeoIP do
  let(:ip_address) { '127.0.0.1' }

  describe '.country_code_from_ip' do
    subject { described_class.country_code_from_ip }

    it 'delegates to an instance of the class' do
      delegate = double(described_class)
      allow(described_class).to receive(:instance).and_return(delegate)
      expect(delegate).to receive(:country_code_from_ip).with(ip_address)
      AlaveteliGeoIP.country_code_from_ip(ip_address)
    end
  end

  describe '.instance' do
    subject { described_class.instance }

    it { is_expected.to be_a(described_class) }

    it 'caches the instance' do
      expect(AlaveteliGeoIP.instance).to equal(AlaveteliGeoIP.instance)
    end
  end

  describe '.new' do
    subject { described_class.new }

    it 'configures the instance with the configured country code' do
      expect(subject.current_code).
        to eq(AlaveteliConfiguration.iso_country_code)
    end

    context 'if a database param is supplied' do
      before do
        allow(File).to receive(:file?).
          with('/my/geoip/database').and_return(true)
      end

      it 'configures the instance with the database specified' do
        expect(GeoIP).to receive(:new).with('/my/geoip/database')
        described_class.new('/my/geoip/database')
      end
    end

    context 'if there is a geoip database configured and present' do
      before do
        allow(File).to receive(:file?).
          with(AlaveteliConfiguration.geoip_database).and_return(true)
      end

      it 'configures the instance with an instance of geoip' do
        expect(GeoIP).to receive(:new).
          with(AlaveteliConfiguration.geoip_database)
        subject
      end
    end

    context 'if there is only a Gaze URL configured' do
      let(:gaze_url) { 'http://gaze.example.net' }

      before do
        allow(AlaveteliConfiguration).to receive(:geoip_database).
          and_return(nil)
        allow(AlaveteliConfiguration).to receive(:gaze_url).
          and_return(gaze_url)
      end

      it 'configures the instance with the Gaze URL' do
        expect(subject.gaze_url).to eq(gaze_url)
      end
    end
  end

  describe '#country_code_from_ip' do
    subject { described_class.new.country_code_from_ip(ip_address) }

    context 'when the Gaze service is configured and is in different states' do
      before(:each) do
        allow(AlaveteliConfiguration).to receive(:geoip_database).and_return ''
      end

      let(:current_code) { described_class.new.current_code }

      context 'the service returns a country code' do
        before do
          allow(AlaveteliConfiguration).to receive(:gaze_url).
            and_return('http://denmark.com')
          stub_request(:get, %r|denmark.com|).to_return(body: 'DK')
        end

        it { is_expected.to eq('DK') }
      end

      context 'the service domain does not exist' do
        before do
          allow(AlaveteliConfiguration).to receive(:gaze_url).
            and_return('http://12123sdf14qsd.com')
          stub_request(:get, %r|12123sdf14qsd.com|).to_raise(SocketError)
        end

        it { is_expected.to eq(current_code) }
      end

      context 'the service does not exist' do
        before do
          allow(AlaveteliConfiguration).to receive(:gaze_url).
            and_return('http://www.google.com')
          stub_request(:get, %r|google.com|).to_return(status: 404)
        end

        it { is_expected.to eq(current_code) }
      end

      context 'the service is not configured' do
        before do
          allow(AlaveteliConfiguration).to receive(:gaze_url).and_return('')
        end

        it { is_expected.to eq(current_code) }
      end

      context 'the service returns an error' do
        before do
          stub_request(:get, %r|500.com|).to_return(status: [500, 'Error'])
          allow(AlaveteliConfiguration).to receive(:gaze_url).
            and_return('http://500.com')
        end

        it 'logs the error url' do
          expect(Rails.logger).to receive(:warn).with /500\.com.*500 Error/
          subject
        end

        it { is_expected.to eq(current_code) }
      end
    end

    context 'when the geoip database is configured' do
      let(:class_instance) { described_class.new }

      let(:geoip) do
        CountryData = Struct.new(:country_code2)
        double('FakeGeoIP', :country => CountryData.new('XX'))
      end

      before do
        allow(class_instance).to receive(:geoip).and_return(geoip)
      end

      it 'returns the country code' do
        expect(class_instance.country_code_from_ip(ip_address)).to eq('XX')
      end
    end
  end
end
