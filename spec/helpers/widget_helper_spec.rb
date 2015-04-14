require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WidgetHelper do

    include WidgetHelper

    describe :status_description do 
    	
    	before do
    		@info_request = FactoryGirl.build(:info_request)
    	end

    	it 'should return "Awaiting classification" for "waiting_classification' do
    		@info_request.stub!(:calculate_status).and_return("waiting_classification")
    		expect(status_description(@info_request)).to eq('Awaiting classification')
    	end

    	it 'should call theme_display_status for a theme status' do
    		@info_request.stub!(:calculate_status).and_return("special_status")
    		@info_request.stub!(:theme_display_status).and_return("Special status")
    		expect(status_description(@info_request)).to eq('Special status')
    	end	

    	it 'should return unknown for an unknown status' do 
    		@info_request.stub!(:calculate_status).and_return("special_status")
    		expect(status_description(@info_request)).to eq('Unknown')
    	end

    end

end