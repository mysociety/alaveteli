# -*- encoding : utf-8 -*-
class AddDateResponseRequiredByToInfoRequest <  ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :info_requests, :date_response_required_by, :date
  end
end
