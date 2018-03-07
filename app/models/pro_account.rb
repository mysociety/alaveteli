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

  def monthly_batch_limit
    super || AlaveteliConfiguration.pro_monthly_batch_limit
  end

  def batches_remaining
    return 0 unless feature_enabled? :pro_batch_access, user
    used_batches = user.info_request_batches.
                     where('created_at > ?', batch_period_start).count
    remaining = monthly_batch_limit - used_batches
    ( remaining > -1 ) ? remaining : 0
  end

  def batches_remaining?
    batches_remaining != 0
  end

  def became_pro
    user.roles(:pro).last.created_at
  end

  def batch_period_start
    this_day_current_month = this_day_and_month(became_pro.day)
    if Time.zone.now.beginning_of_day < this_day_current_month
      if became_pro.day > Time.zone.now.end_of_month.day
        this_day_and_month(became_pro.day, Time.zone.now.last_month.month)
      else
        this_day_current_month - 1.month
      end
    else
      this_day_current_month
    end
  end

  def batch_period_renews
    this_day_next_month =
      this_day_and_month(became_pro.day, Time.zone.now.next_month.month)
    if Time.zone.now.next_month.beginning_of_day < this_day_next_month
      this_day_next_month - 1.month
    else
      this_day_next_month
    end
  end

  def days_to_batch_refresh
    (batch_period_renews.to_date - Time.zone.now.to_date).to_i
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

  def this_day_and_month(day, month = Time.zone.now.month)
    @day || if parse_day_and_month(day, month).day < day
      Time.zone.now.end_of_month.beginning_of_day
    else
      parse_day_and_month(day, month)
    end
  end

  def parse_day_and_month(day, month)
    Time.zone.parse("#{Time.zone.now.year}-#{month}-#{day}")
  end

end
