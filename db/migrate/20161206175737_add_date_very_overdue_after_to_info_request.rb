# -*- encoding : utf-8 -*-
class AddDateVeryOverdueAfterToInfoRequest < ActiveRecord::Migration
  def change
    add_column :info_requests, :date_very_overdue_after, :date
  end
end
