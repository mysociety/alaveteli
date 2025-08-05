# -*- encoding : utf-8 -*-
class AddDateVeryOverdueAfterToInfoRequest < ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :info_requests, :date_very_overdue_after, :date
  end
end
