# -*- encoding : utf-8 -*-
class CreateHolidays < ActiveRecord::Migration
  def self.up
    create_table :holidays do |t|
      t.column :day, :date
      t.column :description, :text
    end
    add_index :holidays, :day

    holidays = {
      # Union of holidays from these places:
      #   http://www.direct.gov.uk/en/Governmentcitizensandrights/LivingintheUK/DG_073741
      #   http://www.dti.gov.uk/employment/bank-public-holidays/
      #   http://www.scotland.gov.uk/Publications/2005/01/bankholidays

      '2007-11-30' => "St. Andrew's Day",
      '2007-12-25' => "Christmas Day",
      '2007-12-26' => "Boxing Day",

      '2008-01-01' => "New Year's Day",
      '2008-01-02' => "2nd January (Scotland)",
      '2008-03-17' => "St. Patrick's Day (NI)",
      '2008-03-21' => "Good Friday",
      '2008-03-24' => "Easter Monday",
      '2008-05-05' => "Early May Bank Holiday",
      '2008-05-26' => "Spring Bank Holiday",
      '2008-07-14' => "Battle of the Boyne (NI)",
      '2008-08-04' => "Summer Bank Holiday (Scotland)",
      '2008-08-25' => "Summer Bank Holiday (England + Wales)",
      '2008-12-01' => "St. Andrew's Day (Scotland)",
      '2008-12-25' => "Christmas Day",
      '2008-12-26' => "Boxing Day",

      '2009-01-01' => "New Year's Day",
      '2009-01-02' => "2nd January (Scotland)",
      '2009-03-17' => "St. Patrick's Day (NI)",
      '2009-04-10' => "Good Friday",
      '2009-04-13' => "Easter Monday",
      '2009-05-04' => "Early May Bank Holiday",
      '2009-05-25' => "Spring Bank Holiday",
      '2009-07-13' => "Battle of the Boyne (NI)",
      '2009-08-03' => "Summer Bank Holiday (Scotland)",
      '2009-08-31' => "Summer Bank Holiday (England + Wales)",
      '2009-11-30' => "St. Andrew's Day (Scotland)",
      '2009-12-25' => "Christmas Day",
      '2009-12-28' => "Boxing Day",

      '2010-01-01' => "New Year's Day",
      '2010-01-04' => "2nd January (Scotland)",
      '2010-03-17' => "St. Patrick's Day (NI)",
      '2010-04-02' => "Good Friday",
      '2010-04-05' => "Easter Monday",
      '2010-05-03' => "Early May Bank Holiday",
      '2010-05-31' => "Spring Bank Holiday",
      '2010-07-12' => "Battle of the Boyne (NI)",
      '2010-08-02' => "Summer Bank Holiday (Scotland)",
      '2010-08-30' => "Summer Bank Holiday (England + Wales)",
      '2010-11-30' => "St. Andrew's Day (Scotland)",
      '2010-12-27' => "Christmas Day",
      '2010-12-28' => "Boxing Day"
    }

    holidays.sort.each { |date, desc|
      Holiday.create :day => date, :description => desc
    }

  end

  def self.down
    drop_table :holidays
  end
end
