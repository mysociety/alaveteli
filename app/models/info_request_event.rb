# == Schema Information
# Schema version: 114
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
#  prominence          :string(255)     default("normal"), not null
#

# models/info_request_event.rb:
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

class InfoRequestEvent < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    belongs_to :outgoing_message
    belongs_to :incoming_message
    belongs_to :comment

    has_many :user_info_request_sent_alerts
    has_many :track_things_sent_emails

    validates_presence_of :event_type

    def self.enumerate_event_types
        [
         'sent',
         'resent',
         'followup_sent',
         'followup_resent',

         'edit', # title etc. edited (in admin interface)
         'edit_outgoing', # outgoing message edited (in admin interface)
         'edit_comment', # comment edited (in admin interface)
         'destroy_incoming', # deleted an incoming message (in admin interface)
         'destroy_outgoing', # deleted an outgoing message (in admin interface)
         'redeliver_incoming', # redelivered an incoming message elsewhere (in admin interface)
         'move_request', # changed user or public body (in admin interface)
         'hide', # hid a request (in admin interface)
         'manual', # you did something in the db by hand

         'response',
         'comment',
         'status_update'
        ]
    end

    validates_inclusion_of :event_type, :in => enumerate_event_types

    # user described state (also update in info_request)
    validate :must_be_valid_state

    # whether event is publicly visible
    validates_inclusion_of :prominence, :in => [
        'normal',
        'hidden',
        'requester_only'
    ]

    def must_be_valid_state
        if !described_state.nil? and !InfoRequest.enumerate_states.include?(described_state)
            errors.add(described_state, "is not a valid state")
        end
    end

    def user_can_view?(user)
        if !self.info_request.user_can_view?(user)
            raise "internal error, called user_can_view? on event when there is not permission to view entire request"
        end

        if self.prominence == 'hidden'
            return User.view_hidden_requests?(user)
        end
        if self.prominence == 'requester_only'
            return self.info_request.is_owning_user?(user)
        end
        return true
    end


    # Full text search indexing
    acts_as_xapian :texts => [ :search_text_main, :title ],
        :values => [
                     [ :created_at, 0, "range_search", :date ], # for QueryParser range searches e.g. 01/01/2008..14/01/2008
                     [ :created_at_numeric, 1, "created_at", :number ], # for sorting
                     [ :described_at_numeric, 2, "described_at", :number ], # XXX using :number for lack of :datetime support in Xapian values
                     [ :request, 3, "request_collapse", :string ],
                     [ :request_title_collapse, 4, "request_title_collapse", :string ],
                   ],
        :terms => [ [ :calculated_state, 'S', "status" ],
                [ :requested_by, 'B', "requested_by" ],
                [ :requested_from, 'F', "requested_from" ],
                [ :commented_by, 'C', "commented_by" ],
                [ :request, 'R', "request" ],
                [ :variety, 'V', "variety" ],
                [ :latest_variety, 'K', "latest_variety" ],
                [ :latest_status, 'L', "latest_status" ],
                [ :waiting_classification, 'W', "waiting_classification" ],
                [ :filetype, 'T', "filetype" ],
                [ :tags, 'U', "tag" ]
        ],
        :if => :indexed_by_search?,
        :eager_load => [ :outgoing_message, :comment, { :info_request => [ :user, :public_body, :censor_rules ] } ]

    def requested_by
        self.info_request.user_name_slug
    end
    def requested_from
        # acts_as_xapian will detect translated fields via Globalize and add all the
        # available locales to the index. But 'requested_from' is not translated directly,
        # although it relies on a translated field in PublicBody. Hence, we need to
        # manually add all the localized values to the index (Xapian can handle a list
        # of values in a term, btw)
        self.info_request.public_body.translations.map {|t| t.url_name}
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

    def latest_variety
        for event in self.info_request.info_request_events.reverse
            if !event.variety.nil? and !event.variety.empty?
                return event.variety
            end
        end
    end

    def latest_status
        for event in self.info_request.info_request_events.reverse
            if !event.calculated_state.nil? and !event.calculated_state.empty?
                return event.calculated_state
            end
        end
        return
    end

    def waiting_classification
        self.info_request.awaiting_description == true ? "yes" : "no"
    end

    def request_title_collapse
        url_title = self.info_request.url_title
        # remove numeric section from the end, use this to group lots
        # of similar requests by
        url_title = url_title.gsub(/[_0-9]+$/, "")
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

    def incoming_message_selective_columns(fields)
        message = IncomingMessage.find(:all,
                                       :select => fields + ", incoming_messages.info_request_id",
                                       :joins => "INNER JOIN info_request_events ON incoming_messages.id = incoming_message_id ",
                                       :conditions => "info_request_events.id = #{self.id}"
                                       )
        message = message[0]
        if !message.nil?
            message.info_request = InfoRequest.find(message.info_request_id)
        end
        return message
    end

    def get_clipped_response_efficiently
        # XXX this ugly code is an attempt to not always load all the
        # columns for an incoming message, which can be *very* large
        # (due to all the cached text).  We care particularly in this
        # case because it's called for every search result on a page
        # (to show the search snippet). Actually, we should review if we
        # need all this data to be cached in the database at all, and
        # then we won't need this horrid workaround.
        message = self.incoming_message_selective_columns("cached_attachment_text_clipped, cached_main_body_text_folded")
        clipped_body = message.cached_main_body_text_folded
        clipped_attachment = message.cached_attachment_text_clipped
        if clipped_body.nil? || clipped_attachment.nil?
            # we're going to have to load it anyway
            text = self.incoming_message.get_text_for_indexing_clipped
        else
            text = clipped_body.gsub("FOLDED_QUOTED_SECTION", " ").strip + "\n\n" + clipped_attachment
        end
        return text + "\n\n"
    end

    # clipped = true - means return shorter text. It is used for snippets fore
    # performance reasons. Xapian will take the full text.
    def search_text_main(clipped = false)
        text = ''
        if self.event_type == 'sent'
            text = text + self.outgoing_message.get_text_for_indexing + "\n\n"
        elsif self.event_type == 'followup_sent'
            text = text + self.outgoing_message.get_text_for_indexing + "\n\n"
        elsif self.event_type == 'response'
            if clipped
                text = text + self.get_clipped_response_efficiently
            else
                text = text + self.incoming_message.get_text_for_indexing_full + "\n\n"
            end
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
            if self.incoming_message.nil?
                raise "event type is 'response' but no incoming message for event id #{self.id}"
            end
            return self.incoming_message.get_present_file_extensions
        end
        return ''
    end
    def tags
        # this returns an array of strings, each gets indexed as separate term by acts_as_xapian
        return self.info_request.tag_array_for_search
    end
    def indexed_by_search?
        if ['sent', 'followup_sent', 'response', 'comment'].include?(self.event_type)
            if !self.info_request.indexed_by_search?
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
    def params_yaml_as_html
        ret = ''
        # split out parameters into old/new diffs, and other ones
        old_params = {}
        new_params = {}
        other_params = {}
        for key, value in self.params
            key = key.to_s
            if key.match(/^old_(.*)$/)
                old_params[$1] = value
            elsif self.params.include?(("old_" + key).to_sym)
                new_params[key] = value
            else
                other_params[key] = value
            end
        end
        # loop through
        for key, value in new_params
            old_value = old_params[key].to_s
            new_value = new_params[key].to_s
            if old_value != new_value
                ret = ret + "<em>" + CGI.escapeHTML(key) + ":</em> "
                ret = ret +
                      CGI.escapeHTML(MySociety::Format.wrap_email_body_by_lines(old_value).strip).gsub(/\n/, '<br>') +
                        " => " +
                      CGI.escapeHTML(MySociety::Format.wrap_email_body_by_lines(new_value).strip).gsub(/\n/, '<br>')
                ret = ret + "<br>"
            end
        end
        for key, value in other_params
            ret = ret + "<em>" + CGI.escapeHTML(key.to_s) + ":</em> "
            ret = ret + CGI.escapeHTML(value.to_s.strip)
            ret = ret + "<br>"
        end
        return ret
    end


    def is_incoming_message?()  not self.incoming_message_selective_columns("incoming_messages.id").nil?  end
    def is_outgoing_message?()  not self.outgoing_message.nil?  end
    def is_comment?()           not self.comment.nil?           end

    # Display version of status
    def display_status
        if is_incoming_message?
            status = self.calculated_state
            return status.nil? ? _("Response") : InfoRequest.get_status_description(status)
        end

        if is_outgoing_message?
            status = self.calculated_state
            if !status.nil?
                if status == 'internal_review'
                    return _("Internal review request")
                end
                if status == 'waiting_response'
                    return _("Clarification")
                end
                raise _("unknown status ") + status
            end
            return _("Follow up")
        end

        raise _("display_status only works for incoming and outgoing messages right now")
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

    def json_for_api(deep, snippet_highlight_proc = nil)
        ret = {
            :id => self.id,
            :event_type => self.event_type,
            # params_yaml has possibly sensitive data in it, don't include it
            :created_at => self.created_at,
            :described_state => self.described_state,
            :calculated_state => self.calculated_state,
            :last_described_at => self.last_described_at,
            :incoming_message_id => self.incoming_message_id,
            :outgoing_message_id => self.outgoing_message_id,
            :comment_id => self.comment_id,

            # XXX would be nice to add links here, but alas the
            # code to make them is in views only. See views/request/details.rhtml
            # perhaps can call with @template somehow
        }

        if self.is_incoming_message? || self.is_outgoing_message?
            ret[:display_status] = self.display_status
        end

        if !snippet_highlight_proc.nil?
            ret[:snippet] = snippet_highlight_proc.call(self.search_text_main(true))
        end

        if deep
            ret[:info_request] = self.info_request.json_for_api(false)
            ret[:public_body] = self.info_request.public_body.json_for_api
            ret[:user] = self.info_request.user.json_for_api
        end

        return ret
    end

  def for_admin_column
    self.class.content_columns.each do |column|
      yield(column.human_name, self.send(column.name), column.type.to_s, column.name)
    end
  end
end
