# -*- encoding : utf-8 -*-
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

    it 'validates that all holidays create from attributes are valid' do
        holiday_import = HolidayImport.new(:source => 'suggestions',
                                           :holidays_attributes => {"0" => {:description => '',
                                                                            "day(1i)"=>"",
                                                                            "day(2i)"=>"",
                                                                            "day(3i)"=>""}})
        holiday_import.valid?.should be_false
        holiday_import.errors[:base].should == ["These holidays could not be imported"]
    end

    it 'validates that all holidays to import are valid' do
        holiday_import = HolidayImport.new
        holiday_import.holidays = [ Holiday.new ]
        holiday_import.valid?.should be_false
        holiday_import.errors[:base].should == ['These holidays could not be imported']
    end

    it 'defaults to importing holidays for the current year' do
        holiday_import = HolidayImport.new
        holiday_import.start_year.should == Time.now.year
        holiday_import.end_year.should == Time.now.year
    end

    it 'allows the start and end year to be set' do
        holiday_import = HolidayImport.new(:start_year => 2011, :end_year => 2012)
        holiday_import.start_year.should == 2011
        holiday_import.end_year.should == 2012
    end

    it 'sets the start and end dates to the beginning and end of the year' do
        holiday_import = HolidayImport.new(:start_year => 2011, :end_year => 2012)
        holiday_import.start_date.should == Date.new(2011, 1, 1)
        holiday_import.end_date.should == Date.new(2012, 12, 31)
    end

    it 'sets a default source of suggestions' do
        holiday_import = HolidayImport.new
        holiday_import.source.should == 'suggestions'
    end

    it 'allows the source to be set' do
        holiday_import = HolidayImport.new(:source => 'feed')
        holiday_import.source.should == 'feed'
    end

    it 'allows an iCal feed URL to be set' do
        holiday_import = HolidayImport.new(:ical_feed_url => 'http://www.example.com')
        holiday_import.ical_feed_url.should == 'http://www.example.com'
    end

    it 'sets a default populated flag to false' do
        holiday_import = HolidayImport.new
        holiday_import.populated.should == false
    end

    it 'returns a readable description of the period for multiple years' do
        HolidayImport.new(:start_year => 2011, :end_year => 2012).period.should == '2011-2012'
    end

    it 'returns a readable description of the period for a single year' do
        HolidayImport.new(:start_year => 2011, :end_year => 2011).period.should == '2011'
    end

    it 'returns the country name for which suggestions are generated' do
        HolidayImport.new.suggestions_country_name.should == 'Germany'
    end

    describe 'when populating a set of holidays to import from suggestions' do

        it 'should populate holidays from the suggestions' do
            holidays = [ { :date => Date.new(2014, 1, 1),
                           :name => "New Year's Day",
                           :regions => [:gb] } ]
            Holidays.stub!(:between).and_return(holidays)
            @holiday_import = HolidayImport.new(:source => 'suggestions')
            @holiday_import.populate

            @holiday_import.holidays.size.should == 1
            holiday = @holiday_import.holidays.first
            holiday.description.should == "New Year's Day"
            holiday.day.should == Date.new(2014, 1, 1)
        end

        it 'returns an empty array for an unknown country code' do
            AlaveteliConfiguration.stub(:iso_country_code).and_return('UNKNOWN_COUNTRY_CODE')
            @holiday_import = HolidayImport.new(:source => 'suggestions')
            @holiday_import.populate
            expect(@holiday_import.holidays).to be_empty
        end

        it 'should return a flag that it has been populated' do
            holidays = [ { :date => Date.new(2014, 1, 1),
                           :name => "New Year's Day",
                           :regions => [:gb] } ]
            Holidays.stub!(:between).and_return(holidays)
            @holiday_import = HolidayImport.new(:source => 'suggestions')
            @holiday_import.populate

            @holiday_import.populated.should == true
        end

    end

    describe 'when populating a set of holidays to import from a feed' do

        before do
            @holiday_import = HolidayImport.new(:source => 'feed',
                                                :ical_feed_url => 'http://www.example.com',
                                                :start_year => 2014,
                                                :end_year => 2014)
        end

        it 'should populate holidays from the feed that are between the dates' do
            @holiday_import.stub!(:open).and_return(load_file_fixture('ical-holidays.ics'))
            @holiday_import.populate
            @holiday_import.holidays.size.should == 1
            holiday = @holiday_import.holidays.first
            holiday.description.should == "New Year's Day"
            holiday.day.should == Date.new(2014, 1, 1)
        end

        it 'should add an error if the calendar cannot be parsed' do
            @holiday_import.stub!(:open).and_return('some invalid data')
            @holiday_import.populate
            expected = ["Sorry, there's a problem with the format of that feed."]
            @holiday_import.errors[:ical_feed_url].should == expected
        end

        it 'should add an error if the calendar cannot be found' do
            @holiday_import.stub!(:open).and_raise Errno::ENOENT.new('No such file or directory')
            @holiday_import.populate
            expected = ["Sorry we couldn't find that feed."]
            @holiday_import.errors[:ical_feed_url].should == expected
        end

    end

    describe 'when saving' do

        it 'saves all holidays' do
            holiday = Holiday.new
            holiday_import = HolidayImport.new
            holiday_import.holidays = [ holiday ]
            holiday.should_receive(:save)
            holiday_import.save
        end

    end

end
