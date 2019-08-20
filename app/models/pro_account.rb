# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: pro_accounts
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  default_embargo_duration :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  stripe_customer_id       :string
#

class ProAccount < ApplicationRecord
  include AlaveteliFeatures::Helpers

  belongs_to :user,
             :inverse_of => :pro_account

  validates :user, presence: true

  def active?
    subscriptions.active.any?
  end

  def subscriptions
    @subscriptions ||= AlaveteliPro::SubscriptionCollection.for_customer(
      stripe_customer
    )
  end

  def stripe_customer
    @stripe_customer ||= stripe_customer!
  end

  def update_stripe_customer
    return unless feature_enabled?(:pro_pricing)

    @stripe_customer = stripe_customer || Stripe::Customer.new

    update_email
    stripe_customer.save
    update(stripe_customer_id: stripe_customer.id)
  end

  private

  def update_email
    return unless stripe_customer.try(:email) != user.email

    stripe_customer.email = user.email
  end

  def stripe_customer!
    Stripe::Customer.retrieve(stripe_customer_id) if stripe_customer_id
  end
end
