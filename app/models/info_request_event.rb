# == Schema Information
# Schema version: 45
#
# Table name: info_request_events
#
#  id              :integer         not null, primary key
#  info_request_id :integer         not null
#  event_type      :text            not null
#  params_yaml     :text            not null
#  created_at      :datetime        not null
#  described_state :string(255)     
#

# models/info_request_event.rb:
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request_event.rb,v 1.25 2008-03-24 09:35:23 francis Exp $

class InfoRequestEvent < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    belongs_to :info_request_event_id

    validates_presence_of :event_type
    validates_inclusion_of :event_type, :in => [
        'sent', 
        'resent', 
        'followup_sent', 
        'edit', # title etc. edited in admin interface
        'edit_outgoing', # outgoing message edited in admin interface
        'manual', # you did something in the db by hand
        'response'
    ]

    # user described state (also update in info_request)
    validates_inclusion_of :described_state, :in => [ 
        nil,
        'waiting_response',
        'waiting_clarification', 
        'not_held',
        'rejected', 
        'successful', 
        'partially_successful',
        'requires_admin'
    ]

    # We store YAML version of parameters in the database
    def params=(params)
        self.params_yaml = params.to_yaml
    end
    def params
        YAML.load(self.params_yaml)
    end

    # Find related incoming message
    # XXX search for the find below and call this function more instead
    def incoming_message
        if not ['response'].include?(self.event_type)
            raise "only call incoming_message for response events"
        end

        if not self.params[:incoming_message_id]
            raise "internal error, no incoming message id for response event"
        end

        return IncomingMessage.find(self.params[:incoming_message_id].to_i)
    end

    # Find related outgoing message
    # XXX search for the find below and call this function more instead
    def outgoing_message
        if not [ 'edit_outgoing', 'sent', 'resent', 'followup_sent' ].include?(self.event_type)
            raise "only call outgoing_message for appropriate event types"
        end

        if not self.params[:outgoing_message_id]
            raise "internal error, no outgoing message id for event type which expected one"
        end

        return OutgoingMessage.find(self.params[:outgoing_message_id].to_i)
    end

end


