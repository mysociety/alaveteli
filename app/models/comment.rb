# == Schema Information
# Schema version: 62
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
# $Id: comment.rb,v 1.1 2008-08-13 01:39:41 francis Exp $

class Comment < ActiveRecord::Base
    belongs_to :user
    #validates_presence_of :user # breaks during construction of new ones :(

    validates_inclusion_of :comment_type, :in => [ 'request' ]
    belongs_to :info_request

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
end


