# -*- encoding : utf-8 -*-
class AddDurationToEmbargo < ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :embargoes, :embargo_duration, :string
  end
end
