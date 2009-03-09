# == Schema Information
# Schema version: 73
#
# Table name: info_request_events
#
#  id                  :integer         not null, primary key
#  info_request_id     :integer         not null
#  event_type          :text            not null
#  params_yaml         :text            not null
#  created_at          :datetime        not null
#  described_state     :string(255)     
#  calculated_state    :string(255)     
#  last_described_at   :datetime        
#  incoming_message_id :integer         
#  outgoing_message_id :integer         
#  comment_id          :integer         
#

# models/info_request_event.rb:
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request_event.rb,v 1.76 2009-03-09 01:17:06 francis Exp $

class InfoRequestEvent < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    belongs_to :outgoing_message
    belongs_to :incoming_message
    belongs_to :comment

    has_many :user_info_request_sent_alerts
    has_many :track_things_sent_emails

    validates_presence_of :event_type
    validates_inclusion_of :event_type, :in => [
        'sent', 
        'resent', 
        'followup_sent', 
        'followup_resent', 
        'edit', # title etc. edited in admin interface
        'edit_outgoing', # outgoing message edited in admin interface
        'edit_comment', # comment edited in admin interface
        'destroy_incoming', # deleted an incoming message
        'redeliver_incoming', # redelivered an incoming message elsewhere
        'manual', # you did something in the db by hand
        'response',
        'comment'
    ]

    # user described state (also update in info_request)
    validates_inclusion_of :described_state, :in => [ 
        nil,
        'waiting_response',
        'waiting_clarification', 
        'gone_postal',
        'not_held',
        'rejected', 
        'successful', 
        'partially_successful',
        'internal_review',
        'error_message',
        'requires_admin',
        'user_withdrawn'
    ]

    # Full text search indexing
    acts_as_xapian :texts => [ :search_text_main, :title ],
        :values => [ 
                     [ :created_at, 0, "range_search", :date ], # for QueryParser range searches e.g. 01/01/2008..14/01/2008
                     [ :created_at_numeric, 1, "created_at", :number ], # for sorting
                     [ :described_at_numeric, 2, "described_at", :number ], # XXX using :number for lack of :datetime support in Xapian values
                     [ :request, 3, "request_collapse", :string ],
                     [ :request_title_collapse, 4, "request_title_collapse", :string ]
                   ],
        :terms => [ [ :calculated_state, 'S', "status" ],
                [ :requested_by, 'B', "requested_by" ],
                [ :requested_from, 'F', "requested_from" ],
                [ :commented_by, 'C', "commented_by" ],
                [ :request, 'R', "request" ],
                [ :variety, 'V', "variety" ],
                [ :filetype, 'T', "filetype" ]
        ],
        :if => :indexed_by_search,
        :eager_load => [ :incoming_message, :outgoing_message, :comment, { :info_request => [ :user, :public_body, :censor_rules ] } ]

    def requested_by
        self.info_request.user.url_name
    end
    def requested_from
        self.info_request.public_body.url_name
    end
    def commented_by
        if self.event_type == 'comment'
            self.comment.user.url_name
        else
            return ''
        end
    end
    def request
        self.info_request.url_title
    end
    def request_title_collapse
        url_title = self.info_request.url_title
        # remove numeric section from the end, use this to group lots
        # of similar requests by
        url_title.gsub!(/[_0-9]+$/, "")
        return url_title
    end
    def described_at
        # For responses, people might have RSS feeds on searches for type of
        # response (e.g. successful) in which case we want to date sort by
        # when the responses was described as being of the type. For other
        # types, just use the create at date.
        return self.last_described_at || self.created_at
    end
    def described_at_numeric
        # format it here as no datetime support in Xapian's value ranges
        return self.described_at.strftime("%Y%m%d%H%M%S") 
    end
    def created_at_numeric
        # format it here as no datetime support in Xapian's value ranges
        return self.created_at.strftime("%Y%m%d%H%M%S") 
    end
    def search_text_main
        text = ''
        if self.event_type == 'sent' 
            text = text + self.outgoing_message.get_text_for_indexing + "\n\n"
        elsif self.event_type == 'followup_sent'
            text = text + self.outgoing_message.get_text_for_indexing + "\n\n"
        elsif self.event_type == 'response'
            text = text + self.incoming_message.get_text_for_indexing + "\n\n"
        elsif self.event_type == 'comment'
            text = text + self.comment.body + "\n\n"
        else
            # nothing
        end
        return text
    end
    def title
        if self.event_type == 'sent' 
            return self.info_request.title
        end
        return ''
    end
    def filetype
        if self.event_type == 'response'
            return self.incoming_message.get_present_file_extensions
        end
        return ''
    end
    def indexed_by_search
        if ['sent', 'followup_sent', 'response', 'comment'].include?(self.event_type)
            if self.info_request.prominence == 'backpage'
                return false
            end
            if self.event_type == 'comment' && !self.comment.visible
                return false
            end
            return true
        else
            return false
        end
    end
    def variety
        self.event_type
    end

    def visible
        if self.event_type == 'comment'
            return self.comment.visible
        end
        return true
    end

    # We store YAML version of parameters in the database
    def params=(params)
        # XXX should really set these explicitly, and stop storing them in
        # here, but keep it for compatibility with old way for now
        if not params[:incoming_message_id].nil?
            self.incoming_message_id = params[:incoming_message_id]
        end
        if not params[:outgoing_message_id].nil?
            self.outgoing_message_id = params[:outgoing_message_id]
        end
        if not params[:comment_id].nil?
            self.comment_id = params[:comment_id]
        end
        self.params_yaml = params.to_yaml
    end
    def params
        YAML.load(self.params_yaml)
    end

    # Display version of status
    def display_status
        if !incoming_message.nil?
            status = self.calculated_state
            if !status.nil?
                if status == 'waiting_response'
                    return "Acknowledgement"
                elsif status == 'waiting_clarification'
                    return "Clarification required"
                elsif status == 'gone_postal'
                    return "Handled by post"
                elsif status == 'not_held'
                    return "Information not held"
                elsif status == 'rejected'
                    return "Rejection"
                elsif status == 'partially_successful'
                    return "Some information sent"
                elsif status == 'successful'
                    return "All information sent"
                elsif status == 'internal_review'
                    return "Internal review acknowledgement"
                elsif status == 'user_withdrawn'
                    return "Withdrawn by requester"
                elsif status == 'error_message'
                    return "Delivery error"
                elsif status == 'requires_admin'
                    return "Unusual response"
                end
                raise "unknown status " + status
            end
            return "Response"
        end

        if !outgoing_message.nil?
            status = self.calculated_state
            if !status.nil?
                if status == 'internal_review'
                    return "Internal review request"
                end
                if status == 'waiting_response'
                    return "Clarification"
                end
                raise "unknown status " + status
            end
            return "Follow up"
        end

        raise "display_status only works for incoming and outgoing messages right now"
    end

    def is_sent_sort?
        if [ 'sent', 'resent'].include?(self.event_type)
            return true
        end
        return false
    end
    def is_followup_sort?
        if [ 'followup_sent', 'followup_resent'].include?(self.event_type)
            return true
        end
        return false
    end

    def same_email_as_previous_send?
        prev_addr = self.info_request.get_previous_email_sent_to(self)
        curr_addr = self.params[:email]
        if prev_addr.nil? && curr_addr.nil?
            return true
        end
        if prev_addr.nil? || curr_addr.nil?
            return false
        end
        return TMail::Address.parse(prev_addr).address == TMail::Address.parse(curr_addr).address
    end

end


