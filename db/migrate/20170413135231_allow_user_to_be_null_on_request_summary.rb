# -*- encoding : utf-8 -*-
class AllowUserToBeNullOnRequestSummary <  ActiveRecord::Migration[4.2] # 4.1
  def change
    change_column_null :request_summaries, :user_id, true
  end
end
