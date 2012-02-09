# config/routes.rb:
# Mapping URLs to controllers for FOIFA.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: routes.rb,v 1.92 2009-10-14 22:01:27 francis Exp $

ActionController::Routing::Routes.draw do |map|
    
    # The priority is based upon order of creation: first created -> highest priority.

    # Sample of regular route:
    # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
    # Keep in mind you can assign values other than :controller and :action

    # Allow easy extension from themes. Note these will have the highest priority.
    require File.join('config', 'custom-routes')
    
    map.with_options :controller => 'general' do |general|
        general.frontpage           '/',            :action => 'frontpage'
        general.blog '/blog', :action => 'blog'
        general.custom_css '/stylesheets/custom.css', :action => 'custom_css'
        general.search_redirect '/search',      :action => 'search_redirect'
        # XXX combined is the search query, and then if sorted a "/newest" at the end.
        # Couldn't find a way to do this in routes which also picked up multiple other slashes
        # and dots and other characters that can appear in search query. So we sort it all
        # out in the controller.
        general.search_general '/search/*combined/all', :action => 'search', :view => 'all'
        general.search_general '/search/*combined', :action => 'search'
        general.advanced_search '/advancedsearch', :action => 'search_redirect', :advanced => true

        general.random_request '/random', :action => 'random_request'

        general.fai_test '/test', :action => 'fai_test'
    end

    map.with_options :controller => 'request' do |request|
        request.request_list_recent   '/list/recent',        :action => 'list', :view => 'recent'
        request.request_list_all   '/list/all',        :action => 'list', :view => 'all'
        request.request_list_successful   '/list/successful',        :action => 'list', :view => 'successful'
        request.request_list_unsuccessful   '/list/unsuccessful',        :action => 'list', :view => 'unsuccessful'
        request.request_list_awaiting   '/list/awaiting',        :action => 'list', :view => 'awaiting'
        request.request_list   '/list',        :action => 'list'

        request.select_authority     '/select_authority',     :action => 'select_authority'
        
        request.new_request    '/new',         :action => 'new'
        request.new_request_to_body    '/new/:url_name',         :action => 'new'

        request.search_ahead '/request/search_ahead',      :action => 'search_typeahead'

        request.show_request     '/request/:url_title.:format', :action => 'show'
        request.show_new_request     '/request/:url_title/new', :action => 'show'
        request.details_request     '/details/request/:url_title', :action => 'details'
        request.similar_request     '/similar/request/:url_title', :action => 'similar'

        request.describe_state   '/request/:id/describe', :action => 'describe_state'
        request.show_response_no_followup    '/request/:id/response', :action => 'show_response'
        request.show_response    '/request/:id/response/:incoming_message_id', :action => 'show_response'
        request.get_attachment_as_html   '/request/:id/response/:incoming_message_id/attach/html/:part/*file_name', :action => 'get_attachment_as_html'
        request.get_attachment   '/request/:id/response/:incoming_message_id/attach/:part/*file_name', :action => 'get_attachment'

        request.info_request_event '/request_event/:info_request_event_id', :action => 'show_request_event'

        request.upload_response "/upload/request/:url_title", :action => 'upload_response'
        request.download_entire_request '/request/:url_title/download',      :action => 'download_entire_request'

    end

    # Use /profile for things to do with the currently signed in user.
    # Use /user/XXXX for things that anyone can see about that user.
    # Note that /profile isn't indexe by search (see robots.txt)
    map.with_options :controller => 'user' do |user|
        user.signin '/profile/sign_in',        :action => 'signin'
        user.signup '/profile/sign_up',        :action => 'signup'
        user.signout '/profile/sign_out',      :action => 'signout'

        user.confirm '/c/:email_token', :action => 'confirm'
        user.show_user '/user/:url_name.:format', :action => 'show'
        user.show_user_profile '/user/:url_name/profile.:format', :action => 'show', :view => 'profile'
        user.show_user_requests '/user/:url_name/requests.:format', :action => 'show', :view => 'requests'
        user.contact_user '/user/contact/:id', :action => 'contact'

        user.signchangepassword '/profile/change_password',      :action => 'signchangepassword'
        user.signchangeemail '/profile/change_email',      :action => 'signchangeemail'

        user.set_profile_photo '/profile/set_photo', :action => 'set_profile_photo'
        user.clear_profile_photo '/profile/clear_photo', :action => 'clear_profile_photo'
        user.get_profile_photo '/user/:url_name/photo.png', :action => 'get_profile_photo'
        user.get_draft_profile_photo '/profile/draft_photo/:id.png', :action => 'get_draft_profile_photo'
        user.set_profile_about_me '/profile/set_about_me', :action => 'set_profile_about_me'

        user.river '/profile/river', :action => 'river'
    end

    map.with_options :controller => 'public_body' do |body|
        body.search_ahead_bodies '/body/search_ahead',      :action => 'search_typeahead'
        body.list_public_bodies "/body", :action => 'list'
        body.list_public_bodies_default "/body/list/all", :action => 'list'
        body.list_public_bodies "/body/list/:tag", :action => 'list'
        body.list_public_bodies_redirect "/local/:tag", :action => 'list_redirect'
        body.all_public_bodies_csv "/body/all-authorities.csv", :action => 'list_all_csv'
        body.show_public_body "/body/:url_name.:format", :action => 'show', :view => 'all'
        body.show_public_body_all "/body/:url_name/all", :action => 'show', :view => 'all'
        body.show_public_body_successful "/body/:url_name/successful", :action => 'show', :view => "successful"
        body.show_public_body_unsuccessful "/body/:url_name/unsuccessful", :action => 'show', :view => "unsuccessful"
        body.show_public_body_awaiting "/body/:url_name/awaiting", :action => 'show', :view => "awaiting"
        body.view_public_body_email "/body/:url_name/view_email", :action => 'view_email'
        body.show_public_body_tag "/body/:url_name/:tag", :action => 'show'
        body.show_public_body_tag_view "/body/:url_name/:tag/:view", :action => 'show'
    end

    map.with_options :controller => 'comment' do |comment|
        comment.new_comment "/annotate/request/:url_title", :action => 'new', :type => 'request'
    end

    map.with_options :controller => 'services' do |service|
        service.other_country_message "/country_message", :action => 'other_country_message'
    end

    map.with_options :controller => 'track' do |track|
        # /track/ is for setting up an email alert for the item
        # /feed/ is a direct RSS feed of the item
        track.track_request '/:feed/request/:url_title.:format', :action => 'track_request', :feed => /(track|feed)/
        track.track_list '/:feed/list/:view.:format', :action => 'track_list', :view => nil, :feed => /(track|feed)/
        track.track_public_body "/:feed/body/:url_name.:format", :action => 'track_public_body', :feed => /(track|feed)/
        track.track_user "/:feed/user/:url_name.:format", :action => 'track_user', :feed => /(track|feed)/
        # XXX must be better way of getting dots and slashes in search queries to work than this *query_array
        # Also, the :format doesn't work. See hacky code in the controller that makes up for this.
        track.track_search "/:feed/search/*query_array.:format", :action => 'track_search_query' , :feed => /(track|feed)/

        track.update '/track/update/:track_id', :action => 'update'
        track.delete_all_type '/track/delete_all_type', :action => 'delete_all_type'
        track.atom_feed '/track/feed/:track_id', :action => 'atom_feed'
    end

    map.with_options :controller => 'help' do |help|
      help.help_unhappy '/help/unhappy/:url_title', :action => 'unhappy'
      help.help_about '/help/about', :action => 'about'
      help.help_alaveteli '/help/alaveteli', :action => 'alaveteli'
      help.help_contact '/help/contact', :action => 'contact'
      help.help_officers '/help/officers', :action => 'officers'
      help.help_requesting '/help/requesting', :action => 'requesting'
      help.help_privacy '/help/privacy', :action => 'privacy'
      help.help_api '/help/api', :action => 'api'
      help.help_credits '/help/credits', :action => 'credits'
      help.help_general '/help/:action', :action => :action
    end

    map.with_options :controller => 'holiday' do |holiday|
        holiday.due_date "/due_date/:holiday", :action => 'due_date'
    end

    map.with_options :controller => 'request_game' do |game|
        game.play '/categorise/play', :action => 'play'
        game.request '/categorise/request/:url_title', :action => 'show'
        game.stop '/categorise/stop', :action => 'stop'
    end

    map.with_options :controller => 'admin_public_body' do |body|
        body.admin_body_missing '/admin/missing_scheme', :action => 'missing_scheme'
        body.admin_body_index '/admin/body', :action => 'index'
        body.admin_body_list '/admin/body/list', :action => 'list'
        body.admin_body_show '/admin/body/show/:id', :action => 'show'
        body.admin_body_new '/admin/body/new/:id', :action => 'new'
        body.admin_body_edit '/admin/body/edit/:id', :action => 'edit'
        body.admin_body_update '/admin/body/update/:id', :action => 'update'
        body.admin_body_create '/admin/body/create/:id', :action => 'create'
        body.admin_body_destroy '/admin/body/destroy/:id', :action => 'destroy'
        body.admin_body_import_csv '/admin/body/import_csv', :action => 'import_csv'
        body.admin_body_mass_tag_add '/admin/body/mass_tag_add', :action => 'mass_tag_add'
    end

    map.with_options :controller => 'admin_general' do |admin|
        admin.admin_general_index '/admin', :action => 'index'
        admin.admin_timeline '/admin/timeline', :action => 'timeline'
        admin.admin_debug '/admin/debug', :action => 'debug'
        admin.admin_stats '/admin/stats', :action => 'stats'
    end

    map.with_options :controller => 'admin_request' do |admin|
        admin.admin_request_list_old_unclassified '/admin/unclassified', :action => 'list_old_unclassified'
        admin.admin_request_index '/admin/request', :action => 'index'
        admin.admin_request_list '/admin/request/list', :action => 'list'
        admin.admin_request_show '/admin/request/show/:id', :action => 'show'
        admin.admin_request_resend '/admin/request/resend', :action => 'resend'
        admin.admin_request_edit '/admin/request/edit/:id', :action => 'edit'
        admin.admin_request_update '/admin/request/update/:id', :action => 'update'
        admin.admin_request_destroy '/admin/request/destroy/:id', :action => 'fully_destroy'
        admin.admin_request_edit_outgoing '/admin/request/edit_outgoing/:id', :action => 'edit_outgoing'
        admin.admin_request_destroy_outgoing '/admin/request/destroy_outgoing/:id', :action => 'destroy_outgoing'
        admin.admin_request_update_outgoing '/admin/request/update_outgoing/:id', :action => 'update_outgoing'
        admin.admin_request_edit_comment '/admin/request/edit_comment/:id', :action => 'edit_comment'
        admin.admin_request_update_comment '/admin/request/update_comment/:id', :action => 'update_comment'
        admin.admin_request_destroy_incoming '/admin/request/destroy_incoming/:id', :action => 'destroy_incoming'
        admin.admin_request_redeliver_incoming '/admin/request/redeliver_incoming', :action => 'redeliver_incoming'
        admin.admin_request_move_request '/admin/request/move_request', :action => 'move_request'
        admin.admin_request_generate_upload_url '/admin/request/generate_upload_url/:id', :action => 'generate_upload_url'
        admin.admin_request_show_raw_email '/admin/request/show_raw_email/:id', :action => 'show_raw_email'
        admin.admin_request_download_raw_email '/admin/request/download_raw_email/:id', :action => 'download_raw_email'
        admin.admin_request_clarification '/admin/request/mark_event_as_clarification', :action => 'mark_event_as_clarification'
    end

    map.with_options :controller => 'admin_user' do |user|
        user.admin_user_index '/admin/user', :action => 'index'
        user.admin_user_list '/admin/user/list', :action => 'list'
        user.admin_user_list_banned '/admin/user/banned', :action => 'list_banned'
        user.admin_user_show '/admin/user/show/:id', :action => 'show'
        user.admin_user_edit '/admin/user/edit/:id', :action => 'edit'
        user.admin_user_show '/admin/user/show_bounce_message/:id', :action => 'show_bounce_message'
        user.admin_user_update '/admin/user/update/:id', :action => 'update'
        user.admin_user_clear_bounce '/admin/user/clear_bounce/:id', :action => 'clear_bounce'
        user.admin_user_destroy_track '/admin/user/destroy_track', :action => 'destroy_track'
        user.admin_user_login_as '/admin/user/login_as/:id', :action => 'login_as'
        user.admin_clear_profile_photo '/admin/user/clear_profile_photo/:id', :action => 'clear_profile_photo'
    end

    map.with_options :controller => 'admin_track' do |track|
        track.admin_track_list '/admin/track/list', :action => 'list'
    end

    map.with_options :controller => 'admin_censor_rule' do |rule|
        rule.admin_rule_new '/admin/censor/new', :action => 'new'
        rule.admin_rule_create '/admin/censor/create', :action => 'create'
        rule.admin_rule_edit '/admin/censor/edit/:id', :action => 'edit'
        rule.admin_rule_update '/admin/censor/update/:id', :action => 'update'
        rule.admin_rule_destroy '/admin/censor/destroy/:censor_rule_id', :action => 'destroy'
    end
    map.filter('conditionallyprependlocale')

    # Allow downloading Web Service WSDL as a file with an extension
    # instead of a file named 'wsdl'
    # map.connect ':controller/service.wsdl', :action => 'wsdl'
end
