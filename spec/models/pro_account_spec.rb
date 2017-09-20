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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'stripe_mock'

describe ProAccount do

  before do
    StripeMock.start
  end

  after do
    StripeMock.stop
  end

  let(:stripe_helper) { StripeMock.create_test_helper }

  describe '#stripe_customer' do

    subject { FactoryGirl.create(:pro_account) }

    let(:customer) do
      Stripe::Customer.create(email: subject.user.email,
                              source: stripe_helper.generate_card_token)
    end

    it 'returns nil if a stripe_customer_id does not exist' do
      expect(subject.stripe_customer).to be_nil
    end

    it 'finds the Stripe::Customer linked to the ProAccount' do
      subject.update!(stripe_customer_id: customer.id)
      expect(subject.stripe_customer).to eq(customer)
    end

  end

  describe '#active?' do

    subject { FactoryGirl.create(:pro_account) }

    let(:customer) do
      Stripe::Customer.create(email: subject.user.email,
                              source: stripe_helper.generate_card_token)
    end

    let(:plan) do
      stripe_helper.create_plan(id: 'pro', amount: 1000)
    end

    before do
      subject.update!(stripe_customer_id: customer.id)
    end

    it 'returns true if there is an active subscription' do
      Stripe::Subscription.create(customer: customer,
                                  plan: plan.id)
      expect(subject.active?).to eq(true)
    end

    it 'returns true if there is an expiring subscription' do
      subscription =
        Stripe::Subscription.create(customer: customer,
                                    plan: plan.id)
      subscription.delete(at_period_end: true)
      expect(subject.active?).to eq(true)
    end

    it 'returns false if an existing subscription is cancelled' do
      subscription =
        Stripe::Subscription.create(customer: customer,
                                    plan: plan.id)
      subscription.delete
      expect(subject.active?).to eq(false)
    end

    it 'returns false if there are no active subscriptions' do
      expect(subject.active?).to eq(false)
    end

  end

end
