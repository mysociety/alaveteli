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
