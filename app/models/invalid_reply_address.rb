# == Schema Information
# Schema version: 20250611141800
#
# Table name: invalid_reply_addresses
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class InvalidReplyAddress < ApplicationRecord
  validates_presence_of :email,
                        message: 'Enter the email address to mark as invalid reply address'

  validates_uniqueness_of :email,
                          message: 'This address is already marked as invalid reply address'

  strip_attributes

  before_save :downcase_email

  def self.invalid?(email_address)
    exists?(email: Array(email_address).compact.map(&:downcase))
  end

  private

  def downcase_email
    email.downcase!
  end
end
