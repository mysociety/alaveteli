# models/outgoing_message.rb:
# A message, associated with a request, from the user of the site to somebody
# else. e.g. An initial request for information, or a complaint.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: outgoing_message.rb,v 1.5 2007-10-16 08:57:32 francis Exp $

class OutgoingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :body
    validates_inclusion_of :status, :in => ['ready', 'sent', 'failed']

    validates_inclusion_of :message_type, :in => ['initial_request'] #, 'complaint']

    def send_message
        if message_type == 'initial_request'
            if status == 'ready'
                # test this with:
                # InfoRequest.find(1).outgoing_messages[0].send_message

                RequestMailer.deliver_initial_request(info_request, self)
            else
                raise "Message id #{id} not ready for send_message"
            end
        else
            raise "Message id #{id} has type '#{message_type}' which send_message can't handle"
        end

    end
end

