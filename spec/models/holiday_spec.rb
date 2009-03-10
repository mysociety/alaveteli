require File.dirname(__FILE__) + '/../spec_helper'

describe Holiday, " when calculating due date" do
    fixtures :holidays

    def due_date(ymd) 
        return Holiday.due_date_from(Date.strptime(ymd)).strftime("%F")
    end

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

    it "handles Saturday start" do
      due_date('2009-03-14').should == '2009-04-16'
    end

    it "handles Sunday start" do
      due_date('2009-03-15').should == '2009-04-16'
    end

    it "handles Monday start" do
      due_date('2009-03-16').should == '2009-04-16' 
    end

end

