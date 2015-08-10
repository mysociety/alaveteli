# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HolidayImport do

  it 'validates the presence of a feed if the source is a feed' do
    holiday_import = HolidayImport.new(:source => 'feed')
    expect(holiday_import.valid?).to be false
    expect(holiday_import.errors[:ical_feed_url]).to eq(["can't be blank"])
  end

  it 'does not validate the presence of a feed if the source is suggestions' do
    holiday_import = HolidayImport.new(:source => 'suggestions')
    expect(holiday_import.valid?).to be true
  end

  it 'validates that the source is either "feed" or "suggestions"' do
    holiday_import = HolidayImport.new(:source => 'something')
    expect(holiday_import.valid?).to be false
    expect(holiday_import.errors[:source]).to eq(["is not included in the list"])
  end

  it 'validates that all holidays create from attributes are valid' do
    holiday_import = HolidayImport.new(:source => 'suggestions',
                                       :holidays_attributes => {"0" => {:description => '',
                                                                        "day(1i)"=>"",
                                                                        "day(2i)"=>"",
                                                                        "day(3i)"=>""}})
    expect(holiday_import.valid?).to be false
    expect(holiday_import.errors[:base]).to eq(["These holidays could not be imported"])
  end

  it 'validates that all holidays to import are valid' do
    holiday_import = HolidayImport.new
    holiday_import.holidays = [ Holiday.new ]
    expect(holiday_import.valid?).to be false
    expect(holiday_import.errors[:base]).to eq(['These holidays could not be imported'])
  end

  it 'defaults to importing holidays for the current year' do
    holiday_import = HolidayImport.new
    expect(holiday_import.start_year).to eq(Time.now.year)
    expect(holiday_import.end_year).to eq(Time.now.year)
  end

  it 'allows the start and end year to be set' do
    holiday_import = HolidayImport.new(:start_year => 2011, :end_year => 2012)
    expect(holiday_import.start_year).to eq(2011)
    expect(holiday_import.end_year).to eq(2012)
  end

  it 'sets the start and end dates to the beginning and end of the year' do
    holiday_import = HolidayImport.new(:start_year => 2011, :end_year => 2012)
    expect(holiday_import.start_date).to eq(Date.new(2011, 1, 1))
    expect(holiday_import.end_date).to eq(Date.new(2012, 12, 31))
  end

  it 'sets a default source of suggestions' do
    holiday_import = HolidayImport.new
    expect(holiday_import.source).to eq('suggestions')
  end

  it 'allows the source to be set' do
    holiday_import = HolidayImport.new(:source => 'feed')
    expect(holiday_import.source).to eq('feed')
  end

  it 'allows an iCal feed URL to be set' do
    holiday_import = HolidayImport.new(:ical_feed_url => 'http://www.example.com')
    expect(holiday_import.ical_feed_url).to eq('http://www.example.com')
  end

  it 'sets a default populated flag to false' do
    holiday_import = HolidayImport.new
    expect(holiday_import.populated).to eq(false)
  end

  it 'returns a readable description of the period for multiple years' do
    expect(HolidayImport.new(:start_year => 2011, :end_year => 2012).period).to eq('2011-2012')
  end

  it 'returns a readable description of the period for a single year' do
    expect(HolidayImport.new(:start_year => 2011, :end_year => 2011).period).to eq('2011')
  end

  it 'returns the country name for which suggestions are generated' do
    expect(HolidayImport.new.suggestions_country_name).to eq('Germany')
  end

  describe 'when populating a set of holidays to import from suggestions' do

    it 'should populate holidays from the suggestions' do
      holidays = [ { :date => Date.new(2014, 1, 1),
                     :name => "New Year's Day",
                     :regions => [:gb] } ]
      allow(Holidays).to receive(:between).and_return(holidays)
      @holiday_import = HolidayImport.new(:source => 'suggestions')
      @holiday_import.populate

      expect(@holiday_import.holidays.size).to eq(1)
      holiday = @holiday_import.holidays.first
      expect(holiday.description).to eq("New Year's Day")
      expect(holiday.day).to eq(Date.new(2014, 1, 1))
    end

    it 'returns an empty array for an unknown country code' do
      allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return('UNKNOWN_COUNTRY_CODE')
      @holiday_import = HolidayImport.new(:source => 'suggestions')
      @holiday_import.populate
      expect(@holiday_import.holidays).to be_empty
    end

    it 'should return a flag that it has been populated' do
      holidays = [ { :date => Date.new(2014, 1, 1),
                     :name => "New Year's Day",
                     :regions => [:gb] } ]
      allow(Holidays).to receive(:between).and_return(holidays)
      @holiday_import = HolidayImport.new(:source => 'suggestions')
      @holiday_import.populate

      expect(@holiday_import.populated).to eq(true)
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
      allow(@holiday_import).to receive(:open).and_return(load_file_fixture('ical-holidays.ics'))
      @holiday_import.populate
      expect(@holiday_import.holidays.size).to eq(1)
      holiday = @holiday_import.holidays.first
      expect(holiday.description).to eq("New Year's Day")
      expect(holiday.day).to eq(Date.new(2014, 1, 1))
    end

    it 'should add an error if the calendar cannot be parsed' do
      allow(@holiday_import).to receive(:open).and_return('some invalid data')
      @holiday_import.populate
      expected = ["Sorry, there's a problem with the format of that feed."]
      expect(@holiday_import.errors[:ical_feed_url]).to eq(expected)
    end

    it 'should add an error if the calendar cannot be found' do
      allow(@holiday_import).to receive(:open).and_raise Errno::ENOENT.new('No such file or directory')
      @holiday_import.populate
      expected = ["Sorry we couldn't find that feed."]
      expect(@holiday_import.errors[:ical_feed_url]).to eq(expected)
    end

  end

  describe 'when saving' do

    it 'saves all holidays' do
      holiday = Holiday.new
      holiday_import = HolidayImport.new
      holiday_import.holidays = [ holiday ]
      expect(holiday).to receive(:save)
      holiday_import.save
    end

  end

end
