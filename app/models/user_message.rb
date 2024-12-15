# == Schema Information
# Schema version: 20230222154014
#
# Table name: user_messages
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class UserMessage < ApplicationRecord
  belongs_to :user,
             inverse_of: :user_messages,
             counter_cache: true,
             optional: true
end
