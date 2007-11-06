# app/helpers/application_helper.rb:
# This module is included into all controllers via controllers/application.rb
# - 
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: link_to_helper.rb,v 1.2 2007-11-06 16:05:29 francis Exp $

module LinkToHelper

    # Links to various models
    # XXX consolidate with simplify_url_part in controllers/application.rb so
    # ones with calls to simplify_url_part are only in one place
   
    def request_link(info_request)
        link_to h(info_request.title), show_request_url(:id => info_request)
    end
    
    def public_body_link_short(public_body)
        link_to h(public_body.short_name), show_public_body_url(:simple_short_name => simplify_url_part(public_body.short_name))
    end
    def public_body_link(public_body)
        link_to h(public_body.name), show_public_body_url(:simple_short_name => simplify_url_part(public_body.short_name))
    end

    def user_link(user)
        link_to h(user.name), show_user_url(:simple_name => simplify_url_part(user.name))
    end

    def info_request_link(info_request)
        link_to h(info_request.title), show_request_url(:id => info_request)
    end

    # Simplified links to our objects
    # XXX See controllers/user_controller.rb controllers/body_controller.rb for inverse
    # XXX consolidate somehow with stuff in helpers/application_helper.rb
    def simplify_url_part(text)
        text = text.downcase # this also clones the string, if we use downcase! we modify the original
        text.gsub!(/ /, "-")
        text.gsub!(/[^a-z0-9_-]/, "")
        text
    end
 
end

