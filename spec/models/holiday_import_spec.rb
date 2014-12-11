require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HolidayImport do

    it 'validates the presence of a feed if the source is a feed' do
        holiday_import = HolidayImport.new(:source => 'feed')
        holiday_import.valid?.should be_false
        holiday_import.errors[:ical_feed_url].should == ["can't be blank"]
    end

    it 'does not validate the presence of a feed if the source is suggestions' do
        holiday_import = HolidayImport.new(:source => 'suggestions')
        holiday_import.valid?.should be_true
    end

    it 'validates that the source is either "feed" or "suggestions"' do
        holiday_import = HolidayImport.new(:source => 'something')
        holiday_import.valid?.should be_false
        holiday_import.errors[:source].should == ["is not included in the list"]
    end

    it 'validates that all holidays are valid' do
        holiday_import = HolidayImport.new(:source => 'suggestions',
                                           :holidays_attributes => {"0" => {:description => '',
                                                                            "day(1i)"=>"",
                                                                            "day(2i)"=>"",
                                                                            "day(3i)"=>""}})
        holiday_import.valid?.should be_false
        holiday_import.errors[:base].should == ["These holidays could not be imported"]
    end

end
