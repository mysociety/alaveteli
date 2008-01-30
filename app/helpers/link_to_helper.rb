# app/helpers/application_helper.rb:
# This module is included into all controllers via controllers/application.rb
# - 
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: link_to_helper.rb,v 1.13 2008-01-30 09:53:47 francis Exp $

module LinkToHelper

    # Links to various models
    # XXX consolidate with simplify_url_part in controllers/application.rb so
    # ones with calls to simplify_url_part are only in one place
   
    def request_url(info_request)
        return show_request_url(:id => info_request, :only_path => true)
    end
    def request_link(info_request)
        link_to h(info_request.title), request_url(info_request)
    end
     
    def public_body_url(public_body)
        return show_public_body_url(:simple_short_name => simplify_url_part(public_body.short_name), :only_path => true)
    end
    def public_body_link_short(public_body)
        link_to h(public_body.short_name), public_body_url(public_body)
    end
    def public_body_link(public_body)
        link_to h(public_body.name), public_body_url(public_body)
    end

    def user_url(user)
        return show_user_url(:simple_name => simplify_url_part(user.name))
    end
    def user_link(user)
        link_to h(user.name), user_url(user)
    end
    def user_or_you_link(user)
        if @user && user == @user
            link_to h("you"), user_url(user)
        else
            link_to h(user.name), user_url(user)
        end
    end
    def user_or_you_capital_link(user)
        if @user && user == @user
            link_to h("You"), user_url(user)
        else
            link_to h(user.name), user_url(user)
        end
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

    def admin_url(relative_path)
        admin_url_prefix = MySociety::Config.get("ADMIN_BASE_URL", "/admin/")
        return admin_url_prefix + relative_path
    end

    # About page URLs
    def about_url
        return help_general_url(:action => 'about')
    end
    def unhappy_url
        return help_general_url(:action => 'unhappy')
    end


    # Where stylesheets used by admin page sit under
    def admin_public_url(relative_path)
        admin_url_prefix = MySociety::Config.get("ADMIN_PUBLIC_URL", "/")
        return admin_url_prefix + relative_path.sub(/^\//, "") # stylesheet relative paths start with /
    end

    def main_url(relative_path)
        url_prefix = "http://" + MySociety::Config.get("DOMAIN", '127.0.0.1:3000')
        return url_prefix + relative_path
    end

    # Basic date format
    def simple_date(date)
        return date.strftime("%e %B %Y")
    end

  
end

