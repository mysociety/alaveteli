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

  describe '.new' do

    it 'should require a day' do
      holiday = Holiday.new
      expect(holiday.valid?).to be false
      expect(holiday.errors[:day]).to eq(["can't be blank"])
    end
  end

  describe " when calculating due date" do

    def due_date(ymd)
      return Holiday.due_date_from_working_days(Date.strptime(ymd), 20).strftime("%F")
    end

    context "in working days" do
      it "handles no holidays" do
        expect(due_date('2008-10-01')).to eq('2008-10-29')
      end

      it "handles non leap years" do
        expect(due_date('2007-02-01')).to eq('2007-03-01')
      end

      it "handles leap years" do
        expect(due_date('2008-02-01')).to eq('2008-02-29')
      end

      it "handles Thursday start" do
        expect(due_date('2009-03-12')).to eq('2009-04-14')
      end

      it "handles Friday start" do
        expect(due_date('2009-03-13')).to eq('2009-04-15')
      end

      # Delivery at the weekend ends up the same due day as if it had arrived on
      # the Friday before. This is because the next working day (Monday) counts
      # as day 1.
      # See http://www.whatdotheyknow.com/help/officers#days
      it "handles Saturday start" do
        expect(due_date('2009-03-14')).to eq('2009-04-15')
      end
      it "handles Sunday start" do
        expect(due_date('2009-03-15')).to eq('2009-04-15')
      end

      it "handles Monday start" do
        expect(due_date('2009-03-16')).to eq('2009-04-16')
      end

      it "handles Time objects" do
        expect(Holiday.due_date_from_working_days(Time.utc(2009, 03, 16, 12, 0, 0), 20).strftime('%F')).to eq('2009-04-16')
      end
    end

    context "in calendar days" do
      it "handles no holidays" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 10, 1), 20)).to eq(Date.new(2008, 10, 21))
      end

      it "handles the due date falling on a Friday" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 10, 4), 20)).to eq(Date.new(2008, 10, 24))
      end

      # If the due date would fall on a Saturday it should in fact fall on the next day that isn't a weekend
      # or a holiday
      it "handles the due date falling on a Saturday" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 10, 5), 20)).to eq(Date.new(2008, 10, 27))
      end

      it "handles the due date falling on a Sunday" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 10, 6), 20)).to eq(Date.new(2008, 10, 27))
      end

      it "handles the due date falling on a Monday" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 10, 7), 20)).to eq(Date.new(2008, 10, 27))
      end

      it "handles the due date falling on a day before a Holiday" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 12, 4), 20)).to eq(Date.new(2008, 12, 24))
      end

      it "handles the due date falling on a Holiday" do
        expect(Holiday.due_date_from_calendar_days(Date.new(2008, 12, 5), 20)).to eq(Date.new(2008, 12, 29))
      end

      it "handles Time objects" do
        expect(Holiday.due_date_from_calendar_days(Time.utc(2009, 03, 17, 12, 0, 0), 20)).to eq(Date.new(2009, 4, 6))
      end
    end
  end
end
