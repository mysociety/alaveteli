require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'when getting a country message' do

    it 'should not raise an IP spoofing error when given mismatched headers' do
        use_gaze_instead_of_geoip_db!
        get '/country_message', nil, { 'HTTP_X_FORWARDED_FOR' => '1.2.3.4',
                                       'HTTP_CLIENT_IP' => '5.5.5.5' }
        response.status.should == 200
    end

end
