# == Schema Information
# Schema version: 78
#
# Table name: comments
#
#  id              :integer         not null, primary key
#  user_id         :integer         not null
#  comment_type    :string(255)     default("internal_error"), not null
#  info_request_id :integer         
#  body            :text            not null
#  visible         :boolean         default(true), not null
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

# models/comments.rb:
# A comment by a user upon something.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: comment.rb,v 1.16 2009-06-26 14:28:37 francis Exp $

class Comment < ActiveRecord::Base
    strip_attributes!

    belongs_to :user
    #validates_presence_of :user # breaks during construction of new ones :(

    validates_inclusion_of :comment_type, :in => [ 'request' ]
    belongs_to :info_request

    has_many :info_request_events # in practice only ever has one

    def body
        ret = read_attribute(:body)
        if ret.nil?
            return ret
        end
        ret = ret.strip
        ret = ret.gsub(/(?:\n\s*){2,}/, "\n\n") # remove excess linebreaks that unnecessarily space it out
        ret
    end
    def raw_body
        read_attribute(:body)
    end

    # So when made invisble it vanishes
    after_save :event_xapian_update
    def event_xapian_update
        for event in self.info_request_events
            event.xapian_mark_needs_index
        end
    end

    # Check have edited comment
    def validate
        if self.body.empty? || self.body =~ /^\s+$/
            errors.add(:body, "^Please enter your annotation")
        end
    end

    # Return body for display as HTML
    def get_body_for_html_display
        text = self.body.strip
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        return text
    end

    # When posting a new comment, use this to check user hasn't double submitted.
    def Comment.find_by_existing_comment(info_request_id, body)
        # XXX can add other databases here which have regexp_replace
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            # Exclude spaces from the body comparison using regexp_replace
            return Comment.find(:first, :conditions => [ "info_request_id = ? and regexp_replace(body, '[[:space:]]', '', 'g') = regexp_replace(?, '[[:space:]]', '', 'g')", info_request_id, body ])
        else
            # For other databases (e.g. SQLite) not the end of the world being space-sensitive for this check
            return Comment.find(:first, :conditions => [ "info_request_id = ? and body = ?", info_request_id, body ])
        end
    end

end


