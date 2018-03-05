class AddMonthlyBatchLimitToProAccount < ActiveRecord::Migration
  def change
    add_column :pro_accounts, :monthly_batch_limit, :integer
  end
end
