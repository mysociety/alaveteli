# encoding: UTF-8
# config/routes.rb:
# Mapping URLs to controllers for FOIFA.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

# Allow easy extension from themes. Note these will have the highest priority.
$alaveteli_route_extensions.each do |f|
    load File.join('config', f)
end

Alaveteli::Application.routes.draw do
    #### General contoller
    match '/' => 'general#frontpage', :as => :frontpage
    match '/blog' => 'general#blog', :as => :blog
    match '/search' => 'general#search_redirect', :as => :search_redirect
    match '/search/all' => 'general#search_redirect', :as => :search_redirect
    # `combined` is the search query, and then if sorted a "/newest" at the end.
    # Couldn't find a way to do this in routes which also picked up multiple other slashes
    # and dots and other characters that can appear in search query. So we sort it all
    # out in the controller.
    match '/search/*combined/all' => 'general#search', :as => :search_general, :view => 'all'
    match '/search(/*combined)' => 'general#search', :as => :search_general
    match '/advancedsearch' => 'general#search_redirect', :as => :advanced_search, :advanced => true
    match '/version.:format' => 'general#version', :as => :version
    #####

    ##### Request controller
    match '/list/recent' => 'request#list', :as => :request_list_recent, :view => 'recent'
    match '/list/all' => 'request#list', :as => :request_list_all, :view => 'all'
    match '/list/successful' => 'request#list', :as => :request_list_successful, :view => 'successful'
    match '/list/unsuccessful' => 'request#list', :as => :request_list_unsuccessful, :view => 'unsuccessful'
    match '/list/awaiting' => 'request#list', :as => :request_list_awaiting, :view => 'awaiting'
    match '/list' => 'request#list', :as => :request_list

    match '/select_authority' => 'request#select_authority', :as => :select_authority
    match '/select_authorities' => 'request#select_authorities', :as => :select_authorities

    match '/new' => 'request#new', :as => :new_request
    match '/new/:url_name' => 'request#new', :as => :new_request_to_body
    match '/new_batch' => 'request#new_batch', :as => :new_batch

    match '/request/search_ahead' => 'request#search_typeahead', :as => :search_ahead

    match '/request/:url_title' => 'request#show', :as => :show_request
    match '/request/:url_title/new' => 'request#show', :as => :show_new_request
    match '/details/request/:url_title' => 'request#details', :as => :details_request
    match '/similar/request/:url_title' => 'request#similar', :as => :similar_request

    match '/request/:id/describe' => 'request#describe_state', :as => :describe_state
    match '/request/:url_title/describe/:described_state' => 'request#describe_state_message', :as => :describe_state_message
    match '/request/:id/response' => 'request#show_response', :as => :show_response_no_followup
    match '/request/:id/response/:incoming_message_id' => 'request#show_response', :as => :show_response
    match '/request/:id/response/:incoming_message_id/attach/html/:part/*file_name' => 'request#get_attachment_as_html', :format => false, :as => :get_attachment_as_html
    match '/request/:id/response/:incoming_message_id/attach/:part(/*file_name)' => 'request#get_attachment', :format => false, :as => :get_attachment

    match '/request_event/:info_request_event_id' => 'request#show_request_event', :as => :info_request_event

    match '/upload/request/:url_title' => 'request#upload_response', :as => :upload_response
    match '/request/:url_title/download' => 'request#download_entire_request', :as => :download_entire_request
    ####

    resources :health_checks, :only => [:index]

    resources :request, :only => [] do
        resource :report, :only => [:new, :create]
    end

    resources :info_request_batch, :only => :show

    #### User controller
    # Use /profile for things to do with the currently signed in user.
    # Use /user/XXXX for things that anyone can see about that user.
    # Note that /profile isn't indexed by search (see robots.txt)
    match '/profile/sign_in' => 'user#signin', :as => :signin
    match '/profile/sign_up' => 'user#signup', :as => :signup, :via => :post
    match '/profile/sign_up' => 'user#signin', :via => :get
    match '/profile/sign_out' => 'user#signout', :as => :signout

    match '/c/:email_token' => 'user#confirm', :as => :confirm
    match '/user/:url_name' => 'user#show', :as => :show_user
    match '/user/:url_name/profile' => 'user#show', :as => :show_user_profile, :view => 'profile'
    match '/user/:url_name/requests' => 'user#show', :as => :show_user_requests, :view => 'requests'
    match '/user/:url_name/wall' => 'user#wall', :as => :show_user_wall
    match '/user/contact/:id' => 'user#contact', :as => :contact_user

    match '/profile/change_password' => 'user#signchangepassword', :as => :signchangepassword
    match '/profile/change_email' => 'user#signchangeemail', :as => :signchangeemail

    match '/profile/set_photo' => 'user#set_profile_photo', :as => :set_profile_photo
    match '/profile/clear_photo' => 'user#clear_profile_photo', :as => :clear_profile_photo
    match '/user/:url_name/photo.png' => 'user#get_profile_photo', :as => :get_profile_photo
    match '/profile/draft_photo/:id.png' => 'user#get_draft_profile_photo', :as => :get_draft_profile_photo
    match '/profile/set_about_me' => 'user#set_profile_about_me', :as => :set_profile_about_me
    match '/profile/set_receive_alerts' => 'user#set_receive_email_alerts', :as => :set_receive_email_alerts
    match '/profile/river' => 'user#river', :as => :river
    ####

    #### PublicBody controller
    match '/body/search_ahead' => 'public_body#search_typeahead', :as => :search_ahead_bodies
    match '/body' => 'public_body#list', :as => :list_public_bodies
    match '/body/list/all' => 'public_body#list', :as => :list_public_bodies_default
    match '/body/list/:tag' => 'public_body#list', :as => :list_public_bodies
    match '/local/:tag' => 'public_body#list_redirect', :as => :list_public_bodies_redirect
    match '/body/all-authorities.csv' => 'public_body#list_all_csv', :as => :all_public_bodies_csv
    match '/body/:url_name' => 'public_body#show', :as => :show_public_body, :view => 'all'
    match '/body/:url_name/all' => 'public_body#show', :as => :show_public_body_all, :view => 'all'
    match '/body/:url_name/successful' => 'public_body#show', :as => :show_public_body_successful, :view => 'successful'
    match '/body/:url_name/unsuccessful' => 'public_body#show', :as => :show_public_body_unsuccessful, :view => 'unsuccessful'
    match '/body/:url_name/awaiting' => 'public_body#show', :as => :show_public_body_awaiting, :view => 'awaiting'
    match '/body/:url_name/view_email' => 'public_body#view_email', :as => :view_public_body_email
    match '/body/:url_name/:tag' => 'public_body#show', :as => :show_public_body_tag
    match '/body/:url_name/:tag/:view' => 'public_body#show', :as => :show_public_body_tag_view
    match '/body_statistics' => 'public_body#statistics', :as => :public_bodies_statistics
    ####

    resource :change_request, :only => [:new, :create], :controller => 'public_body_change_requests'

    #### Comment controller
    match '/annotate/request/:url_title' => 'comment#new', :as => :new_comment, :type => 'request'
    ####

    #### Services controller
    match '/country_message' => 'services#other_country_message', :as => :other_country_message
    match '/hidden_user_explanation' => 'services#hidden_user_explanation', :as => :hidden_user_explanation
    ####

    #### Track controller
    # /track/ is for setting up an email alert for the item
    # /feed/ is a direct RSS feed of the item
    match '/:feed/request/:url_title' => 'track#track_request', :as => :track_request, :feed => /(track|feed)/
    match '/:feed/list/:view' => 'track#track_list', :as => :track_list, :view => nil, :feed => /(track|feed)/
    match '/:feed/body/:url_name' => 'track#track_public_body', :as => :track_public_body, :feed => /(track|feed)/
    match '/:feed/user/:url_name' => 'track#track_user', :as => :track_user, :feed => /(track|feed)/
    # TODO: :format doesn't work. See hacky code in the controller that makes up for this.
    match '/:feed/search/:query_array' => 'track#track_search_query',
          :as => :track_search,
          :feed => /(track|feed)/,
          :constraints => { :query_array => /.*/ }

    match '/track/update/:track_id' => 'track#update', :as => :update
    match '/track/delete_all_type' => 'track#delete_all_type', :as => :delete_all_type
    match '/track/feed/:track_id' => 'track#atom_feed', :as => :atom_feed
    ####

    #### Help controller
    match '/help/unhappy/:url_title' => 'help#unhappy', :as => :help_unhappy
    match '/help/about' => 'help#about', :as => :help_about
    match '/help/alaveteli' => 'help#alaveteli', :as => :help_alaveteli
    match '/help/contact' => 'help#contact', :as => :help_contact
    match '/help/officers' => 'help#officers', :as => :help_officers
    match '/help/requesting' => 'help#requesting', :as => :help_requesting
    match '/help/privacy' => 'help#privacy', :as => :help_privacy
    match '/help/api' => 'help#api', :as => :help_api
    match '/help/credits' => 'help#credits', :as => :help_credits
    match '/help/:action' => 'help#action', :as => :help_general
    match '/help' => 'help#index'
    ####

    #### Holiday controller
    match '/due_date/:holiday' => 'holiday#due_date', :as => :due_date
    ####

    #### RequestGame controller
    match '/categorise/play' => 'request_game#play', :as => :categorise_play
    match '/categorise/request/:url_title' => 'request_game#show', :as => :categorise_request
    match '/categorise/stop' => 'request_game#stop', :as => :categorise_stop
    ####

    #### AdminPublicBody controller
    match '/admin/missing_scheme' => 'admin_public_body#missing_scheme', :as => :admin_body_missing
    match '/admin/body' => 'admin_public_body#index', :as => :admin_body_index
    match '/admin/body/list' => 'admin_public_body#list', :as => :admin_body_list
    match '/admin/body/show/:id' => 'admin_public_body#show', :as => :admin_body_show
    match '/admin/body/new' => 'admin_public_body#new', :as => :admin_body_new
    match '/admin/body/edit/:id' => 'admin_public_body#edit', :as => :admin_body_edit
    match '/admin/body/update/:id' => 'admin_public_body#update', :as => :admin_body_update
    match '/admin/body/create' => 'admin_public_body#create', :as => :admin_body_create
    match '/admin/body/destroy/:id' => 'admin_public_body#destroy', :as => :admin_body_destroy
    match '/admin/body/import_csv' => 'admin_public_body#import_csv', :as => :admin_body_import_csv
    match '/admin/body/mass_tag_add' => 'admin_public_body#mass_tag_add', :as => :admin_body_mass_tag_add
    ####

    #### AdminPublicBodyCategory controller
    scope '/admin', :as => 'admin' do
        resources :categories,
                  :controller => 'admin_public_body_categories'
    end
    ####

    #### AdminPublicBodyHeading controller
    scope '/admin', :as => 'admin'  do
        resources :headings,
                  :controller => 'admin_public_body_headings',
                  :except => [:index] do
                      post 'reorder', :on => :collection
                      post 'reorder_categories', :on => :member
        end
    end
    ####

    #### AdminPublicBodyChangeRequest controller
    match '/admin/change_request/edit/:id' => 'admin_public_body_change_requests#edit', :as => :admin_change_request_edit
    match '/admin/change_request/update/:id' => 'admin_public_body_change_requests#update', :as => :admin_change_request_update
    ####

    #### AdminGeneral controller
    match '/admin' => 'admin_general#index', :as => :admin_general_index
    match '/admin/timeline' => 'admin_general#timeline', :as => :admin_timeline
    match '/admin/debug' => 'admin_general#debug', :as => :admin_debug
    match '/admin/stats' => 'admin_general#stats', :as => :admin_stats
    ####

    #### AdminRequest controller
    scope '/admin', :as => 'admin' do
        resources :requests,
                  :controller => 'admin_request',
                  :except => [:new, :create] do
                      post 'move', :on => :member
                      post 'generate_upload_url', :on => :member
        end
    end
    match '/admin/request/show_raw_email/:id' => 'admin_request#show_raw_email', :as => :admin_request_show_raw_email
    match '/admin/request/download_raw_email/:id' => 'admin_request#download_raw_email', :as => :admin_request_download_raw_email
    match '/admin/request/mark_event_as_clarification' => 'admin_request#mark_event_as_clarification', :as => :admin_request_clarification
    match '/admin/request/hide/:id' => 'admin_request#hide_request', :as => :admin_request_hide
    ####

    #### AdminComment controller
    scope '/admin', :as => 'admin' do
        resources :comments,
                  :controller => 'admin_comment',
                  :only => [:edit, :update]
    end
    ####

    #### AdminIncomingMessage controller
    match '/admin/incoming/destroy' => 'admin_incoming_message#destroy', :as => :admin_incoming_destroy
    match '/admin/incoming/redeliver' => 'admin_incoming_message#redeliver', :as => :admin_incoming_redeliver
    match '/admin/incoming/edit/:id' => 'admin_incoming_message#edit', :as => :admin_incoming_edit
    match '/admin/incoming/update/:id' => 'admin_incoming_message#update', :as => :admin_incoming_update
    ####

    #### AdminOutgoingMessage controller
    match '/admin/outgoing/edit/:id' => 'admin_outgoing_message#edit', :as => :admin_outgoing_edit
    match '/admin/outgoing/destroy/:id' => 'admin_outgoing_message#destroy', :as => :admin_outgoing_destroy
    match '/admin/outgoing/update/:id' => 'admin_outgoing_message#update', :as => :admin_outgoing_update
    match '/admin/outgoing/resend/:id' => 'admin_outgoing_message#resend', :as => :admin_outgoing_resend
    ####

    #### AdminUser controller
    match '/admin/user' => 'admin_user#index', :as => :admin_user_index
    match '/admin/user/list' => 'admin_user#list', :as => :admin_user_list
    match '/admin/user/banned' => 'admin_user#list_banned', :as => :admin_user_list_banned
    match '/admin/user/show/:id' => 'admin_user#show', :as => :admin_user_show
    match '/admin/user/edit/:id' => 'admin_user#edit', :as => :admin_user_edit
    match '/admin/user/show_bounce_message/:id' => 'admin_user#show_bounce_message', :as => :admin_user_show_bounce
    match '/admin/user/update/:id' => 'admin_user#update', :as => :admin_user_update
    match '/admin/user/clear_bounce/:id' => 'admin_user#clear_bounce', :as => :admin_user_clear_bounce
    match '/admin/user/destroy_track' => 'admin_user#destroy_track', :as => :admin_user_destroy_track
    match '/admin/user/login_as/:id' => 'admin_user#login_as', :as => :admin_user_login_as
    match '/admin/user/clear_profile_photo/:id' => 'admin_user#clear_profile_photo', :as => :admin_clear_profile_photo
    match '/admin/user/modify_comment_visibility/:id' => 'admin_user#modify_comment_visibility', :as => 'admin_user_modify_comment_visibility'
    ####

    #### AdminTrack controller
    match '/admin/track/list' => 'admin_track#list', :as => :admin_track_list
    ####

    #### AdminCensorRule controller
    match '/admin/censor/new' => 'admin_censor_rule#new', :as => :admin_rule_new
    match '/admin/censor/create' => 'admin_censor_rule#create', :as => :admin_rule_create
    match '/admin/censor/edit/:id' => 'admin_censor_rule#edit', :as => :admin_rule_edit
    match '/admin/censor/update/:id' => 'admin_censor_rule#update', :as => :admin_rule_update
    match '/admin/censor/destroy/:censor_rule_id' => 'admin_censor_rule#destroy', :as => :admin_rule_destroy

    scope '/admin', :as => 'admin' do
        resources :info_requests, :only => [] do
            resources :censor_rules,
                      :controller => 'admin_censor_rule',
                      :only => [:new, :create],
                      :name_prefix => 'info_request_'
        end
    end

    scope '/admin', :as => 'admin' do
        resources :users, :only => [] do
            resources :censor_rules,
                      :controller => 'admin_censor_rule',
                      :only => [:new, :create],
                      :name_prefix => 'user_'
        end
    end
    ####

    #### AdminSpamAddresses controller
    scope '/admin', :as => 'admin' do
        resources :spam_addresses,
                  :controller => 'admin_spam_addresses',
                  :only => [:index, :create, :destroy]
    end
    ####

    #### Api controller
    match '/api/v2/request.json' => 'api#create_request', :as => :api_create_request, :via => :post

    match '/api/v2/request/:id.json' => 'api#show_request', :as => :api_show_request, :via => :get
    match '/api/v2/request/:id.json' => 'api#add_correspondence', :as => :api_add_correspondence, :via => :post
    match '/api/v2/request/:id/update.json' => 'api#update_state', :as => :api_update_state, :via => :post

    match '/api/v2/body/:id/request_events.:feed_type' => 'api#body_request_events', :as => :api_body_request_events, :feed_type => '^(json|atom)$'
    ####

    filter :conditionallyprependlocale
end
