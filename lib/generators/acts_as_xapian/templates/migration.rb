# -*- encoding : utf-8 -*-
class CreateActsAsXapian < ActiveRecord::Migration
  def self.up
    create_table :acts_as_xapian_jobs do |t|
      t.column :model, :string, :null => false
      t.column :model_id, :integer, :null => false
      t.column :action, :string, :null => false
    end
    add_index :acts_as_xapian_jobs, [:model, :model_id], :unique => true
  end
  def self.down
    drop_table :acts_as_xapian_jobs
  end
end

