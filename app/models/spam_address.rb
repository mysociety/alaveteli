# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: spam_addresses
#
#  id         :integer          not null, primary key
#  email      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SpamAddress < ActiveRecord::Base
  attr_accessible :email

  validates_presence_of :email, :message => 'Please enter the email address to mark as spam'
  validates_uniqueness_of :email, :message => 'This address is already marked as spam'

  def self.spam?(email_address)
    exists?(:email => email_address)
  end

end
