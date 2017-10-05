# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: pro_accounts
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  default_embargo_duration :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class ProAccount < ActiveRecord::Base
  belongs_to :user,
             :inverse_of => :pro_account

  def active?
    stripe_customer.present? && stripe_customer.subscriptions.any?
  end

  def stripe_customer
    @stripe_customer ||= stripe_customer!
  end

  def stripe_customer!
    Stripe::Customer.retrieve(stripe_customer_id) if stripe_customer_id
  end
end
