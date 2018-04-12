# -*- encoding: utf-8 -*-
class AddStripeCustomerIdToProAccount < ActiveRecord::Migration
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
    if table_exists?(table)
      connection.column_exists?(table, column)
    end
  end

  def table_exists?(table)
    connection.table_exists?(table)
  end
end
