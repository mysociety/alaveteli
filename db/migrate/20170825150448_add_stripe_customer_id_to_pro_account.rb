# -*- encoding: utf-8 -*-
class AddStripeCustomerIdToProAccount < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:pro_accounts, :stripe_customer_id)
      add_column :pro_accounts, :stripe_customer_id, :string
    end
  end

  def down
    if column_exists?(:pro_accounts, :stripe_customer_id)
      remove_column :pro_accounts, :stripe_customer_id
    end
  end

  private

  def column_exists?(table, column)
    connection.column_exists?(table, column) if data_source_exists?(table)
  end

  def data_source_exists?(table)
    connection.data_source_exists?(table)
  end
end
