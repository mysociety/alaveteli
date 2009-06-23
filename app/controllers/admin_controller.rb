# controllers/admin.rb:
# All admin controllers are dervied from this.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.25 2009-06-23 13:52:25 francis Exp $


class AdminController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

    # Always give full stack trace for admin interface
    def local_request?
        true
    end

    # Expire cached attachment files for a request
    def expire_for_request(info_request)
        # So is using latest censor rules
        info_request.reload

        # clear out cached entries
        for incoming_message in info_request.incoming_messages
            for attachment in incoming_message.get_attachments_for_display
                expire_page :controller => 'request', :action => "get_attachment", :id => info_request.id,
                    :incoming_message_id => incoming_message.id, 
                    :part => attachment.url_part_number, :file_name => attachment.display_filename
                expire_page :controller => 'request', :action => "get_attachment_as_html", :id => info_request.id,
                    :incoming_message_id => incoming_message.id, 
                    :part => attachment.url_part_number, :file_name => attachment.display_filename
            end
        end
    end


end

