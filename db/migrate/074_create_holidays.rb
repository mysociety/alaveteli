require 'active_record/fixtures'  

class CreateHolidays < ActiveRecord::Migration
  def self.up
    create_table :holidays do |t|
      t.column :day, :date
      t.column :description, :text 
    end
    add_index :holidays, :day

    # Load our default holiday list
    Fixtures.create_fixtures('spec/fixtures', 'holidays')

  end

  def self.down
    drop_table :holidays
  end
end
