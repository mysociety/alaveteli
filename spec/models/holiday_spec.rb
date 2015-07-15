# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: holidays
#
#  id          :integer          not null, primary key
#  day         :date
#  description :text
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Holiday do

  describe :new do

    it 'should require a day' do
      holiday = Holiday.new
      holiday.valid?.should be_false
      holiday.errors[:day].should == ["can't be blank"]
    end
  end

  describe " when calculating due date" do

    def due_date(ymd)
      return Holiday.due_date_from_working_days(Date.strptime(ymd), 20).strftime("%F")
    end

    context "in working days" do
      it "handles no holidays" do
        due_date('2008-10-01').should == '2008-10-29'
      end

      it "handles non leap years" do
        due_date('2007-02-01').should == '2007-03-01'
      end

      it "handles leap years" do
        due_date('2008-02-01').should == '2008-02-29'
      end

      it "handles Thursday start" do
        due_date('2009-03-12').should == '2009-04-14'
      end

      it "handles Friday start" do
        due_date('2009-03-13').should == '2009-04-15'
      end

      # Delivery at the weekend ends up the same due day as if it had arrived on
      # the Friday before. This is because the next working day (Monday) counts
      # as day 1.
      # See http://www.whatdotheyknow.com/help/officers#days
      it "handles Saturday start" do
        due_date('2009-03-14').should == '2009-04-15'
      end
      it "handles Sunday start" do
        due_date('2009-03-15').should == '2009-04-15'
      end

      it "handles Monday start" do
        due_date('2009-03-16').should == '2009-04-16'
      end

      it "handles Time objects" do
        Holiday.due_date_from_working_days(Time.utc(2009, 03, 16, 12, 0, 0), 20).strftime('%F').should == '2009-04-16'
      end
    end

    context "in calendar days" do
      it "handles no holidays" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 10, 1), 20).should == Date.new(2008, 10, 21)
      end

      it "handles the due date falling on a Friday" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 10, 4), 20).should == Date.new(2008, 10, 24)
      end

      # If the due date would fall on a Saturday it should in fact fall on the next day that isn't a weekend
      # or a holiday
      it "handles the due date falling on a Saturday" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 10, 5), 20).should == Date.new(2008, 10, 27)
      end

      it "handles the due date falling on a Sunday" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 10, 6), 20).should == Date.new(2008, 10, 27)
      end

      it "handles the due date falling on a Monday" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 10, 7), 20).should == Date.new(2008, 10, 27)
      end

      it "handles the due date falling on a day before a Holiday" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 12, 4), 20).should == Date.new(2008, 12, 24)
      end

      it "handles the due date falling on a Holiday" do
        Holiday.due_date_from_calendar_days(Date.new(2008, 12, 5), 20).should == Date.new(2008, 12, 29)
      end

      it "handles Time objects" do
        Holiday.due_date_from_calendar_days(Time.utc(2009, 03, 17, 12, 0, 0), 20).should == Date.new(2009, 4, 6)
      end
    end
  end
end
