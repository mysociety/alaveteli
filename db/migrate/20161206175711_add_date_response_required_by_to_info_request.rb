# -*- encoding : utf-8 -*-
class AddDateResponseRequiredByToInfoRequest < ActiveRecord::Migration
  def change
    add_column :info_requests, :date_response_required_by, :date
  end
end
