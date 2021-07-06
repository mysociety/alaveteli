class RemoveInfoRequestLawUsedDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :info_requests, :law_used, from: 'foi', to: nil
  end
end
