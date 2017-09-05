# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-pro-login
class AlaveteliPro::SubscriptionsController < ApplicationController
  before_filter :authenticate

  # TODO: remove reminder of Stripe params once shipped
  #
  # params =>
  # {"utf8"=>"✓",
  #  "authenticity_token"=>"Ono2YgLcl1eC1gGzyd7Vf5HJJhOek31yFpT+8z+tKoo=",
  #  "stripeToken"=>"tok_s3kr3t…",
  #  "stripeTokenType"=>"card",
  #  "stripeEmail"=>"bob@example.com",
  #  "controller"=>"alaveteli_pro/subscriptions",
  #  "action"=>"create"}
  def create
    @token = Stripe::Token.retrieve(params[:stripeToken])

    existing_customer_id = current_user.pro_account.try(:stripe_customer_id)

    @customer =
      if existing_customer_id
        customer = Stripe::Customer.retrieve(existing_customer_id)
        customer.source = @token.id
        customer.save
        customer
      else
        customer =
          Stripe::Customer.create(email: params[:stripeEmail],
                                  source: @token)

        current_user.create_pro_account(stripe_customer_id: customer.id)
        customer
      end

    begin
      @subscription =
        Stripe::Subscription.create(customer: @customer,
                                    plan: params[:plan_id],
                                    tax_percent: 20.0)
    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to plan_path(params[:plan_id])
      return
    end

    current_user.add_role(:pro)

    redirect_to alaveteli_pro_dashboard_path
  end

  private

  def authenticate
    post_redirect_params = {
      :web => _('To upgrade your account'),
      :email => _('To upgrade your account'),
      :email_subject => _('To upgrade your account') }

    authenticated?(post_redirect_params)
  end
end
