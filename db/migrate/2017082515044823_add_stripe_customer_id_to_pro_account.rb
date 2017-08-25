# -*- encoding: utf-8 -*-
class AddStripeCustomerIdToProAccount < ActiveRecord::Migration
  def change
    add_column :pro_accounts, :stripe_customer_id, :string
  end
end
