# app/helpers/link_to_helper.rb:
# This module is included into all controllers via controllers/application.rb
# - 
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: link_to_helper.rb,v 1.40 2008-09-07 16:55:55 francis Exp $

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
    def request_both_links(info_request)
        link_to(h(info_request.title), main_url(request_url(info_request))) + " (" + link_to("admin", request_admin_url(info_request)) + ")"
    end
    def request_similar_url(info_request)
        return similar_request_url(:url_title => info_request.url_title, :only_path => true)
    end

    # Incoming / outgoing messages
    def incoming_message_url(incoming_message)
        return request_url(incoming_message.info_request)+"#incoming-"+incoming_message.id.to_s
    end
    def outgoing_message_url(outgoing_message)
        return request_url(outgoing_message.info_request)+"#outgoing-"+outgoing_message.id.to_s
    end
    def comment_url(comment)
        return request_url(comment.info_request)+"#comment-"+comment.id.to_s
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
    def public_body_both_links(public_body)
        link_to(h(public_body.name), main_url(public_body_url(public_body))) + " (" + link_to("admin", public_body_admin_url(public_body)) + ")"
    end
    def list_public_bodies_default
        list_public_bodies_url(:tag => 'a') 
    end

    # Users
    def user_url(user)
        return show_user_url(:url_name => user.url_name, :only_path => true)
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
    def user_or_you_capital(user)
        if @user && user == @user
            return h("You")
        else
            return h(user.name)
        end
    end
    def user_or_you_capital_link(user)
        link_to user_or_you_capital(user), user_url(user)
    end
    def user_admin_url(user)
        return admin_url('user/show/' + user.id.to_s)
    end
    def user_both_links(user)
        link_to(h(user.name), main_url(user_url(user))) + " (" + link_to("admin", user_admin_url(user)) + ")"
    end

    # Tracks. feed can be 'track' or 'feed'
    def do_track_url(track_thing, feed = 'track')
        if track_thing.track_type == 'request_updates'
            track_request_url(:url_title => track_thing.info_request.url_title, :feed => feed)
        elsif track_thing.track_type == 'all_new_requests' 
            track_list_url(:view => nil, :feed => feed)
        elsif track_thing.track_type == 'all_successful_requests' 
            track_list_url(:view => 'successful', :feed => feed)
        elsif track_thing.track_type == 'public_body_updates' 
            track_public_body_url(:url_name => track_thing.public_body.url_name, :feed => feed)
        elsif track_thing.track_type == 'user_updates' 
            track_user_url(:url_name => track_thing.tracked_user.url_name, :feed => feed)
        elsif track_thing.track_type == 'search_query' 
            track_search_url(:query_array => track_thing.track_query, :feed => feed)
        else
            raise "unknown tracking type " + track_thing.track_type
        end
    end

    # General pages. postfix is either the sort order, or 'bodies' to show you
    # came from the front page and are looking for public bodies
    def search_url(query, postfix = nil)
        url = search_general_url(:combined => query)
        if !postfix.nil? && !postfix.empty?
            url = url + "/" + postfix
        end
        return url
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
        return date.strftime("%e %B %Y").strip
    end

  
end

