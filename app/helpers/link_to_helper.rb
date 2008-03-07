# app/helpers/application_helper.rb:
# This module is included into all controllers via controllers/application.rb
# - 
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: link_to_helper.rb,v 1.22 2008-03-07 23:13:38 francis Exp $

module LinkToHelper

    # Links to various models
   
    # Requests
    def request_url(info_request)
        return show_request_url(:url_title => info_request.url_title, :only_path => true)
    end
    def request_link(info_request)
        link_to h(info_request.title), request_url(info_request)
    end
    def request_admin_url(info_request)
        return admin_url('request/show/' + info_request.id.to_s)
    end
    def request_admin_link(info_request)
        link_to h(info_request.title), request_admin_url(info_request)
    end
 
    # Public bodies
    def public_body_url(public_body)
        return show_public_body_url(:url_name => public_body.url_name, :only_path => true)
    end
    def public_body_link_short(public_body)
        link_to h(public_body.short_or_long_name), public_body_url(public_body)
    end
    def public_body_link(public_body)
        link_to h(public_body.name), public_body_url(public_body)
    end
    def public_body_admin_url(public_body)
        return admin_url('body/show/' + public_body.id.to_s)
    end
    def public_body_admin_link(public_body)
        link_to h(public_body.name), public_body_admin_url(public_body)
    end
    def public_body_admin_link_short(public_body)
        link_to h(public_body.short_or_long_name), public_body_admin_url(public_body)
    end

    # Users
    def user_url(user)
        return show_user_url(:url_name => user.url_name, :only_path => true) + "#user-" + user.id.to_s
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
    def user_admin_url(user)
        return admin_url('user/show/' + user.id.to_s)
    end
    def user_admin_link(user)
        link_to h(user.name), user_admin_url(user)
    end


    # Admin pages
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

