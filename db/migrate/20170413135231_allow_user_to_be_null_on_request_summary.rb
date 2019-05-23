# -*- encoding : utf-8 -*-
class AllowUserToBeNullOnRequestSummary < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 4.1
  def change
    change_column_null :request_summaries, :user_id, true
  end
end
