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

  CardError = Class.new(StandardError)

  attr_writer :token

  belongs_to :user,
             inverse_of: :pro_account

  validates :user, presence: true

  strip_attributes only: %i[default_embargo_duration]

  def subscription?
    subscriptions.current.any?
  end

  def subscriptions
    @subscriptions ||= AlaveteliPro::SubscriptionCollection.for_customer(
      stripe_customer
    )
  end

  def invoices
    @invoices ||= AlaveteliPro::InvoiceCollection.for_customer(
      stripe_customer
    )
  end

  def stripe_customer
    @stripe_customer ||= stripe_customer!
  end

  def update_stripe_customer
    return unless feature_enabled?(:pro_pricing)

    @subscriptions = nil unless stripe_customer

    attributes = {}
    attributes[:source] = @token.id if @token

    if stripe_customer&.email != user.email && user.email !~ /@localhost$/
      attributes[:email] = user.email
    end

    @stripe_customer = (
      if attributes.empty?
        stripe_customer
      elsif stripe_customer
        Stripe::Customer.update(stripe_customer.id, attributes)
      else
        Stripe::Customer.create(attributes)
      end
    )

    update(stripe_customer_id: @stripe_customer&.id)
  end

  private

  def stripe_customer!
    return unless stripe_customer_id

    AlaveteliPro::Customer.retrieve(stripe_customer_id)
  end
end
