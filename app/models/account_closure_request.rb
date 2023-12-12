# == Schema Information
# Schema version: 20230718062820
#
# Table name: account_closure_requests
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AccountClosureRequest < ApplicationRecord
  belongs_to :user
end
