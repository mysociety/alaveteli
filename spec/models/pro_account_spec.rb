# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe ProAccount, :type => :model do
  let(:account) { FactoryGirl.create(:pro_account) }

  it "belongs to a user" do
    expect(account.user).not_to be_nil
  end

  it "has a default_embargo_duration field" do
    account.default_embargo_duration = "3_months"
    expect(account.default_embargo_duration).to eq "3_months"
  end
end
