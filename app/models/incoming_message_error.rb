# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: incoming_message_errors
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  unique_id  :string(255)      not null
#  retry_at   :datetime
#  backtrace  :text
#
# models/incoming_message_error.rb:
#
# Store details of errors that have been generated when trying to import
# emails from a POP mailbox into the application. Used by AlaveteliMailPoller
# to record errors and to determine whether to retry importing a given mail.
# The unique_id field represents the unique identifier applied to a given
# mail in the POP mailbox.
class IncomingMessageError < ActiveRecord::Base

  validates_presence_of :unique_id
end
