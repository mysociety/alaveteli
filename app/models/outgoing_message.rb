# models/outgoing_message.rb:
# A message, associated with a request, from the user of the site to somebody
# else. e.g. An initial request for information, or a complaint.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: outgoing_message.rb,v 1.8 2007-10-30 14:23:21 francis Exp $

class OutgoingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :body
    validates_inclusion_of :status, :in => ['ready', 'sent', 'failed']

    validates_inclusion_of :message_type, :in => ['initial_request'] #, 'complaint']

    # Deliver outgoing message
    # Note: You can test this from script/console with, say:
    # InfoRequest.find(1).outgoing_messages[0].send_message
    def send_message
        if self.message_type == 'initial_request'
            if self.status == 'ready'
                RequestMailer.deliver_initial_request(self.info_request, self)
                self.sent_at = Time.now
                self.status = 'sent'
                self.save!
            elsif self.status == 'sent'
                raise "Message id #{self.id} has already been sent"
            else
                raise "Message id #{self.id} not in state for send_message"
            end
        else
            raise "Message id #{self.id} has type '#{self.message_type}' which send_message can't handle"
        end

    end
end

