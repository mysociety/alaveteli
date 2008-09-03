# config/routes.rb:
# Mapping URLs to controllers for FOIFA.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: routes.rb,v 1.69 2008-09-03 00:48:55 francis Exp $

ActionController::Routing::Routes.draw do |map|

    # The priority is based upon order of creation: first created -> highest priority.

    # Sample of regular route:
    # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
    # Keep in mind you can assign values other than :controller and :action
    
    map.with_options :controller => 'general' do |general|
        general.frontpage           '/',            :action => 'frontpage'
        general.new_frontpage           '/new_frontpage',            :action => 'new_frontpage'
        general.auto_complete_for_public_body_query 'auto_complete_for_public_body_query', :action => 'auto_complete_for_public_body_query'

        general.search_redirect '/search',      :action => 'search_redirect'
        # XXX combined is the search query, and then if sorted a "/newest" at the end.
        # Couldn't find a way to do this in routes which also picked up multiple other slashes
        # and dots and other characters that can appear in search query. So we sort it all
        # out in the controller.
        general.search_general '/search/*combined',      :action => 'search'

        general.fai_test '/test', :action => 'fai_test'
    end

    map.with_options :controller => 'request' do |request|
        request.request_list   '/list/:view',        :action => 'list', :view => nil

        request.new_request    '/new',         :action => 'new'
        request.new_request_to_body    '/new/:public_body_id',         :action => 'new'

        request.show_request     '/request/:url_title', :action => 'show'
        request.similar_request     '/request/:url_title/similar', :action => 'similar'

        request.describe_state   '/request/:id/describe', :action => 'describe_state'
        request.show_response_no_followup    '/request/:id/response', :action => 'show_response'
        request.show_response    '/request/:id/response/:incoming_message_id', :action => 'show_response'
        request.get_attachment   '/request/:id/response/:incoming_message_id/attach/:part/*file_name', :action => 'get_attachment'

        request.info_request_event '/request_event/:info_request_event_id', :action => 'show_request_event'

        request.upload_response "/upload/request/:url_title", :action => 'upload_response'
    end

    map.with_options :controller => 'user' do |user|
        user.signin '/signin',        :action => 'signin'
        user.signup '/signup',        :action => 'signup'
        user.signout '/signout',      :action => 'signout'
        user.signchange '/signchange',      :action => 'signchange'
        user.confirm '/c/:email_token', :action => 'confirm'
        user.show_user '/user/:url_name', :action => 'show'
        user.contact_user '/user/contact/:id', :action => 'contact'
    end

    map.with_options :controller => 'body' do |body|
        body.list_public_bodies "/body", :action => 'list'
        body.list_public_bodies "/body/list/:tag", :action => 'list'
        body.show_public_body "/body/:url_name", :action => 'show'
    end

    map.with_options :controller => 'comment' do |comment|
        comment.new_comment "/annotate/request/:url_title", :action => 'new', :type => 'request'
    end

    map.with_options :controller => 'track' do |track|
        # /track/ is for setting up an email alert for the item
        # /feed/ is a direct RSS feed of the item
        track.track_request '/:feed/request/:url_title', :action => 'track_request', :feed => /(track|feed)/
        track.track_list '/:feed/list/:view', :action => 'track_list', :view => nil, :feed => /(track|feed)/
        track.track_public_body "/:feed/body/:url_name", :action => 'track_public_body', :feed => /(track|feed)/
        track.track_user "/:feed/user/:url_name", :action => 'track_user', :feed => /(track|feed)/
        # XXX must be better way of getting dots and slashes in search queries to work than this *query_array
        track.track_search "/:feed/search/*query_array", :action => 'track_search_query' , :feed => /(track|feed)/

        track.update '/track/update/:track_id', :action => 'update'
        track.atom_feed '/track/feed/:track_id', :action => 'atom_feed'
    end

    map.with_options :controller => 'help' do |help|
      help.help_general '/help/:action',            :action => :action
    end

    # NB: We don't use routes to *construct* admin URLs, as they need to be relative
    # paths to work on the live site proxied over HTTPS to secure.mysociety.org
    map.connect '/admin/', :controller => 'admin', :action => 'index'
    map.connect '/admin/timeline', :controller => 'admin', :action => 'timeline'
    map.connect '/admin/debug', :controller => 'admin', :action => 'debug'
    map.connect '/admin/stats', :controller => 'admin', :action => 'stats'
    map.connect '/admin/body/:action/:id', :controller => 'admin_public_body'
    map.connect '/admin/request/:action/:id', :controller => 'admin_request'
    map.connect '/admin/user/:action/:id', :controller => 'admin_user'
    map.connect '/admin/track/:action/:id', :controller => 'admin_track'

    # Sample of named route:
    # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
    # This route can be invoked with purchase_url(:id => product.id)

    # You can have the root of your site routed by hooking up '' 
    # -- just remember to delete public/index.html.
    # map.connect '', :controller => "welcome"

    # Allow downloading Web Service WSDL as a file with an extension
    # instead of a file named 'wsdl'
    map.connect ':controller/service.wsdl', :action => 'wsdl'

    # Install the default route as the lowest priority.
    # FAI: Turned off for now, as to be honest I don't trust it from a security point of view.
    # Somebody is bound to leave a method public in a controller that shouldn't be.
    #map.connect ':controller/:action/:id.:format'
    #map.connect ':controller/:action/:id'
    # map.connect '/:controller/:action'
end

