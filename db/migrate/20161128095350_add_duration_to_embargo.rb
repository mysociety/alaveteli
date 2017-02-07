class AddDurationToEmbargo < ActiveRecord::Migration
  def change
    add_column :embargoes, :embargo_duration, :string
  end
end
