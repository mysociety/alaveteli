# -*- encoding : utf-8 -*-
class RemoveDefaultValueFromRequestCreatedAtAndRequestUpdatedAtOnRequestSummary <  ActiveRecord::Migration[4.2] # 4.1
  def up
    change_column_default :request_summaries, :request_created_at, nil
    change_column_default :request_summaries, :request_updated_at, nil
  end

  def down
    change_column_default :request_summaries, :request_created_at, Time.now
    change_column_default :request_summaries, :request_updated_at, Time.now
  end
end
