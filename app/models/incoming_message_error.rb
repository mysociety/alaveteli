# -*- encoding : utf-8 -*-
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
