# -*- encoding : utf-8 -*-
class AllowUserToBeNullOnRequestSummary < ActiveRecord::Migration
  def change
    change_column_null :request_summaries, :user_id, true
  end
end
