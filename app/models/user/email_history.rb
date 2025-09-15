# == Schema Information
#
# Table name: user_email_histories
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  old_email  :string           not null
#  new_email  :string           not null
#  changed_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User::EmailHistory < ApplicationRecord
  belongs_to :user

  validates :old_email, presence: true
  validates :new_email, presence: true
  validates :changed_at, presence: true

  # Create a history record for an email change
  def self.record_change(old_email, new_email)
    create!(
      old_email: old_email,
      new_email: new_email,
      changed_at: Time.current
    )
  end
end
