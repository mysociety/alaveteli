# -*- encoding : utf-8 -*-
class MakeSummarisableNotNull <  ActiveRecord::Migration[4.2] # 4.1
  def change
    change_column_null :request_summaries, :summarisable_type, false
    change_column_null :request_summaries, :summarisable_id, false
  end
end
