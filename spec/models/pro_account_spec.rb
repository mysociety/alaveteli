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

end
