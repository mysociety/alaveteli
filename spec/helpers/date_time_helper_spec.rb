# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DateTimeHelper do

  include DateTimeHelper

  describe :simple_date do

    it 'formats a date in html by default' do
      time = Time.utc(2012, 11, 07, 21, 30, 26)
      self.should_receive(:simple_date_html).with(time)
      simple_date(time)
    end

    it 'formats a date in the specified format' do
      time = Time.utc(2012, 11, 07, 21, 30, 26)
      self.should_receive(:simple_date_text).with(time)
      simple_date(time, :format => :text)
    end

    it 'raises an argument error if given an unrecognized format' do
      time = Time.utc(2012, 11, 07, 21, 30, 26)
      expect { simple_date(time, :format => :unknown) }.to raise_error(ArgumentError)
    end

  end

  describe :simple_date_html do

    it 'formats a date in a time tag' do
      Time.use_zone('London') do
        time = Time.utc(2012, 11, 07, 21, 30, 26)
        expected = %Q(<time datetime="2012-11-07T21:30:26+00:00" title="2012-11-07 21:30:26 +0000">November 07, 2012</time>)
        simple_date_html(time).should == expected
      end
    end

  end

  describe :simple_date_text do

    it 'should respect time zones' do
      Time.use_zone('Australia/Sydney') do
        simple_date_text(Time.utc(2012, 11, 07, 21, 30, 26)).should == 'November 08, 2012'
      end
    end

    it 'should handle Date objects' do
      simple_date_text(Date.new(2012, 11, 21)).should == 'November 21, 2012'
    end

  end

  describe :simple_time do

    it 'returns 00:00:00 for a date' do
      simple_time(Date.new(2012, 11, 21)).should == '00:00:00'
    end

    it 'returns the time component of a datetime' do
      date = DateTime.new(2012, 11, 21, 10, 34, 56)
      simple_time(date).should == '10:34:56'
    end

    it 'returns the time component of a time' do
      time = Time.utc(2000, 'jan', 1, 20, 15, 1)
      simple_time(time).should == '20:15:01'
    end

  end
end
