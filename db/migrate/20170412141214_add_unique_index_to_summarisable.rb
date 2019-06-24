# -*- encoding : utf-8 -*-
class AddUniqueIndexToSummarisable <  ActiveRecord::Migration[4.2] # 4.1
  def change
    add_index :request_summaries,
              [:summarisable_type, :summarisable_id],
              :unique => true,
              :name => "index_request_summaries_on_summarisable"
  end
end
