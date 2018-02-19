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

class ProAccount < ActiveRecord::Base
  include AlaveteliFeatures::Helpers

  belongs_to :user,
             :inverse_of => :pro_account

  validates :user, presence: true

  before_create :set_stripe_customer_id

  def active?
    stripe_customer.present? && stripe_customer.subscriptions.any?
  end

  def stripe_customer
    @stripe_customer ||= stripe_customer!
  end

  def update_email_address
    return unless stripe_customer
    stripe_customer.email = user.email
    stripe_customer.save
  end

  private

  def set_stripe_customer_id
    return unless feature_enabled? :pro_pricing
    self.stripe_customer_id ||= begin
      @stripe_customer = Stripe::Customer.create(email: user.email)
      stripe_customer.id
    end
  end

  def stripe_customer!
    Stripe::Customer.retrieve(stripe_customer_id) if stripe_customer_id
  end
end
