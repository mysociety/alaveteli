# -*- encoding : utf-8 -*-
class CreateAlaveteliProRequestSummaryCategories <  ActiveRecord::Migration[4.2] # 4.1
  def change
    create_table :request_summary_categories do |t|
      t.text :slug, :unique => true
      t.timestamps :null => false
    end

    create_join_table :request_summaries, :request_summary_categories,
                      table_name: 'request_summaries_summary_categories' do |t|
      t.index [:request_summary_id, :request_summary_category_id],
              :unique => :true,
              :name => 'index_request_summaries_summary_categories_unique'
      t.index [:request_summary_category_id, :request_summary_id],
              :unique => :true,
              :name => 'index_request_summary_categories_summaries_unique'
    end
  end
end
