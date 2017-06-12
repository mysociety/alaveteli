# -*- encoding : utf-8 -*-
class AddDurationToEmbargo < ActiveRecord::Migration
  def change
    add_column :embargoes, :embargo_duration, :string
  end
end
