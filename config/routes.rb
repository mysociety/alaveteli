# -*- encoding : utf-8 -*-
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
  match '/' => 'general#frontpage',
        :as => :frontpage,
        :via => :get
  match '/blog' => 'general#blog',
        :as => :blog,
        :via => :get
  match '/search' => 'general#search_redirect',
        :as => :search_redirect,
        :via => :get
  match '/search/all' => 'general#search_redirect',
        :as => :search_redirect_all,
        :via => :get
  # `combined` is the search query, and then if sorted a "/newest" at the end.
  # Couldn't find a way to do this in routes which also picked up multiple other slashes
  # and dots and other characters that can appear in search query. So we sort it all
  # out in the controller.
  match '/search/*combined/all' => 'general#search',
        :as => :search_general_all,
        :view => 'all',
        :via => :get
  match '/search(/*combined)' => 'general#search',
        :as => :search_general,
        :via => :get
  match '/advancedsearch' => 'general#search_redirect',
        :as => :advanced_search,
        :advanced => true,
        :via => :get
  match '/version.:format' => 'general#version',
        :as => :version,
        :via => :get
  #####

  ##### Request controller
  match '/list/recent' => 'request#list',
        :as => :request_list_recent,
        :view => 'recent',
        :via => :get
  match '/list/all' => 'request#list',
        :as => :request_list_all,
        :view => 'all',
        :via => :get
  match '/list/successful' => 'request#list',
        :as => :request_list_successful,
        :view => 'successful',
        :via => :get
  match '/list/unsuccessful' => 'request#list',
        :as => :request_list_unsuccessful,
        :view => 'unsuccessful',
        :via => :get
  match '/list/awaiting' => 'request#list',
        :as => :request_list_awaiting,
        :view => 'awaiting',
        :via => :get
  match '/list' => 'request#list',
        :as => :request_list,
        :via => :get

  match '/select_authority' => 'request#select_authority',
        :as => :select_authority,
        :via => :get
  match '/select_authorities' => 'request#select_authorities',
        :as => :select_authorities,
        :via => :get

  match '/new' => 'request#new',
        :as => :new_request,
        :via => [:get, :post]
  match '/new/:url_name' => 'request#new',
        :as => :new_request_to_body,
        :via => [:get, :post]
  match '/new_batch' => 'request#new_batch',
        :as => :new_batch,
        :via => [:get, :post]

  match '/request/search_ahead' => 'request#search_typeahead',
        :as => :search_ahead,
        :via => :get

  match '/request/:url_title' => 'request#show',
        :as => :show_request,
        :via => :get
  match '/request/:url_title/new' => 'request#show',
        :as => :show_new_request,
        :via => :get
  match '/details/request/:url_title' => 'request#details',
        :as => :details_request,
        :via => :get
  match '/similar/request/:url_title' => 'request#similar',
        :as => :similar_request,
        :via => :get

  match '/request/:id/describe' => 'request#describe_state',
        :as => :describe_state,
        :via => [:post, :put]
  match '/request/:url_title/describe/:described_state' => 'request#describe_state_message',
        :as => :describe_state_message,
        :via => :get
  match '/request/:id/response/:incoming_message_id/attach/html/:part/*file_name' => 'request#get_attachment_as_html',
        :format => false,
        :as => :get_attachment_as_html,
        :via => :get
  match '/request/:id/response/:incoming_message_id/attach/:part(/*file_name)' => 'request#get_attachment',
        :format => false,
        :as => :get_attachment,
        :via => :get

  match '/request_event/:info_request_event_id' => 'request#show_request_event',
        :as => :info_request_event,
        :via => :get

  match '/upload/request/:url_title' => 'request#upload_response',
        :as => :upload_response,
        :via => [:get, :post]
  match '/request/:url_title/download' => 'request#download_entire_request',
        :as => :download_entire_request,
        :via => :get
  ####

  #### Followups controller
  match '/request/:request_id/followups/new' => 'followups#new',
        :as => :new_request_followup,
        :via => :get
  match '/request/:request_id/followups/new/:incoming_message_id' => 'followups#new',
        :as => :new_request_incoming_followup,
        :via => :get
  match '/request/:request_id/followups/preview' => 'followups#preview',
        :as => :preview_request_followups,
        :via => :post
  match '/request/:request_id/followups' => 'followups#create',
        :as => :request_followups,
        :via => :post
  ####

  resources :health_checks, :only => [:index]

  resources :request, :only => [] do
    resource :report, :only => [:new, :create]
    resource :widget, :only => [:new, :show]
    resources :widget_votes, :only => [:create]
  end

  resources :info_request_batch, :only => :show

  #### OutgoingMessage controller
  resources :outgoing_messages, :only => [] do
    resource :delivery_status, :only => [:show], :module => 'outgoing_messages'
  end
  ####

  #### User controller
  # Use /profile for things to do with the currently signed in user.
  # Use /user/XXXX for things that anyone can see about that user.
  # Note that /profile isn't indexed by search (see robots.txt)
  resource :password_change,
           :only => [:new, :create, :edit, :update],
           :path => '/profile/change_password',
           :path_names => { :edit => '' }

  resource :one_time_password,
           :only => [:show, :create, :update, :destroy],
           :path => '/profile/two_factor'

  match '/profile/sign_in' => 'user#signin',
        :as => :signin,
        :via => [:get, :post]
  match '/profile/sign_up' => 'user#signup',
        :as => :signup, :via => :post
  match '/profile/sign_up' => 'user#signin',
        :via => :get
  match '/profile/sign_out' => 'user#signout',
        :as => :signout,
        :via => :get

  match '/c/:email_token' => 'user#confirm',
        :as => :confirm,
        :via => :get
  match '/user/:url_name' => 'user#show',
        :as => :show_user,
        :via => :get
  match '/user/:url_name/profile' => 'user#show',
        :as => :show_user_profile,
        :view => 'profile',
        :via => :get
  match '/user/:url_name/requests' => 'user#show',
        :as => :show_user_requests,
        :view => 'requests',
        :via => :get
  match '/user/:url_name/wall' => 'user#wall',
        :as => :show_user_wall,
        :via => :get
  match '/user/contact/:id' => 'user#contact',
        :as => :contact_user,
        :via => [:get, :post]
  match '/profile/change_email' => 'user#signchangeemail',
        :as => :signchangeemail,
        :via => [:get, :post]
  match '/profile/set_photo' => 'user#set_profile_photo',
        :as => :set_profile_photo,
        :via => [:get, :post]
  match '/profile/clear_photo' => 'user#clear_profile_photo',
        :as => :clear_profile_photo,
        :via => :post
  match '/user/:url_name/photo.png' => 'user#get_profile_photo',
        :as => :get_profile_photo,
        :via => :get
  match '/profile/draft_photo/:id.png' => 'user#get_draft_profile_photo',
        :as => :get_draft_profile_photo,
        :via => :get

  namespace :profile, :module => 'user_profile' do
    resource :about_me, :only => [:edit, :update], :controller => 'about_me'
  end

  # Legacy route for setting about_me
  match '/profile/set_about_me' => redirect('/profile/about_me/edit'),
        :as => :set_profile_about_me

  match '/profile/set_receive_alerts' => 'user#set_receive_email_alerts',
        :as => :set_receive_email_alerts

  match '/profile/river' => 'user#river',
        :as => :river,
        :via => :get
  ####

  #### PublicBody controller
  match '/body/search_ahead' => 'public_body#search_typeahead',
        :as => :search_ahead_bodies,
        :via => :get
  match '/body' => 'public_body#list',
        :as => :list_public_bodies,
        :via => :get
  match '/body/list/all' => 'public_body#list',
        :as => :list_public_bodies_default,
        :via => :get
  match '/body/list/:tag' => 'public_body#list',
        :as => :list_public_bodies_by_tag,
        :via => :get
  match '/local/:tag' => 'public_body#list_redirect',
        :as => :list_public_bodies_redirect,
        :via => :get
  match '/body/all-authorities.csv' => 'public_body#list_all_csv',
        :as => :all_public_bodies_csv,
        :via => :get
  match '/body/:url_name' => 'public_body#show',
        :as => :show_public_body, :view => 'all',
        :via => :get
  match '/body/:url_name/all' => 'public_body#show',
        :as => :show_public_body_all,
        :view => 'all',
        :via => :get
  match '/body/:url_name/successful' => 'public_body#show',
        :as => :show_public_body_successful,
        :view => 'successful',
        :via => :get
  match '/body/:url_name/unsuccessful' => 'public_body#show',
        :as => :show_public_body_unsuccessful,
        :view => 'unsuccessful',
        :via => :get
  match '/body/:url_name/awaiting' => 'public_body#show',
        :as => :show_public_body_awaiting,
        :view => 'awaiting',
        :via => :get
  match '/body/:url_name/view_email' => 'public_body#view_email',
        :as => :view_public_body_email,
        :via => [:get, :post]
  match '/body/:url_name/:tag' => 'public_body#show',
        :as => :show_public_body_tag,
        :via => :get
  match '/body/:url_name/:tag/:view' => 'public_body#show',
        :as => :show_public_body_tag_view,
        :via => :get
  match '/body_statistics' => 'public_body#statistics',
        :as => :public_bodies_statistics,
        :via => :get
  ####

  resource :change_request, :only => [:new, :create], :controller => 'public_body_change_requests'

  #### Comment controller
  match '/annotate/request/:url_title' => 'comment#new',
        :as => :new_comment,
        :type => 'request',
        :via => [:get, :post]
  ####

  #### Services controller
  match '/country_message' => 'services#other_country_message',
        :as => :other_country_message,
        :via => :get
  match '/hidden_user_explanation' => 'services#hidden_user_explanation',
        :as => :hidden_user_explanation,
        :via => :get
  ####

  #### Track controller
  # /track/ is for setting up an email alert for the item
  # /feed/ is a direct RSS feed of the item
  match '/:feed/request/:url_title' => 'track#track_request',
        :as => :track_request,
        :feed => /(track|feed)/,
        :via => :get
  match '/:feed/list/:view' => 'track#track_list',
        :as => :track_list,
        :view => nil,
        :feed => /(track|feed)/,
        :via => :get
  match '/:feed/body/:url_name' => 'track#track_public_body',
        :as => :track_public_body,
        :feed => /(track|feed)/,
        :via => :get
  match '/:feed/user/:url_name' => 'track#track_user',
        :as => :track_user,
        :feed => /(track|feed)/,
        :via => :get
  # TODO: :format doesn't work. See hacky code in the controller that makes up for this.
  match '/:feed/search/:query_array' => 'track#track_search_query',
        :as => :track_search,
        :feed => /(track|feed)/,
        :constraints => { :query_array => /.*/ },
        :via => :get

  match '/track/update/:track_id' => 'track#update',
        :as => :update,
        :via => [:get, :post]
  match '/track/delete_all_type' => 'track#delete_all_type',
        :as => :delete_all_type,
        :via => :post
  match '/track/feed/:track_id' => 'track#atom_feed',
        :as => :atom_feed,
        :via => :get
  ####

  #### Help controller
  match '/help/unhappy/:url_title' => 'help#unhappy',
        :as => :help_unhappy,
        :via => :get
  match '/help/about' => 'help#about',
        :as => :help_about,
        :via => :get
  match '/help/alaveteli' => 'help#alaveteli',
        :as => :help_alaveteli,
        :via => :get
  match '/help/contact' => 'help#contact',
        :as => :help_contact,
        :via => [:get, :post]
  match '/help/officers' => 'help#officers',
        :as => :help_officers,
        :via => :get
  match '/help/requesting' => 'help#requesting',
        :as => :help_requesting,
        :via => :get
  match '/help/privacy' => 'help#privacy',
        :as => :help_privacy,
        :via => :get
  match '/help/api' => 'help#api',
        :as => :help_api,
        :via => :get
  match '/help/credits' => 'help#credits',
        :as => :help_credits,
        :via => :get
  match '/help/:action' => 'help#action',
        :as => :help_general,
        :via => :get
  match '/help' => 'help#index',
        :via => :get
  ####

  #### Holiday controller
  match '/due_date/:holiday' => 'holiday#due_date',
        :as => :due_date,
        :via => :get
  ####

  #### RequestGame controller
  match '/categorise/play' => 'request_game#play',
        :as => :categorise_play,
        :via => :get
  match '/categorise/request/:url_title' => 'request_game#show',
        :as => :categorise_request,
        :via => :get
  match '/categorise/stop' => 'request_game#stop',
        :as => :categorise_stop,
        :via => :get
  ####

  #### AdminPublicBody controller
  scope '/admin', :as => 'admin' do
    resources :bodies,
    :controller => 'admin_public_body' do
      get 'missing_scheme', :on => :collection
      post 'mass_tag_add', :on => :collection
      get 'import_csv', :on => :collection
      post 'import_csv', :on => :collection
      resources :censor_rules,
        :controller => 'admin_censor_rule',
        :only => [:new, :create]
    end
  end
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

  #### AdminHoliday controller
  scope '/admin', :as => 'admin' do
    resources :holidays,
      :controller => 'admin_holidays'
  end
  ####

  #### AdminHolidayImports controller
  scope '/admin', :as => 'admin' do
    resources :holiday_imports,
      :controller => 'admin_holiday_imports',
      :only => [:new, :create]
  end
  ####

  #### AdminPublicBodyChangeRequest controller
  scope '/admin', :as => 'admin'  do
    resources :change_requests,
      :controller => 'admin_public_body_change_requests',
      :only => [:edit, :update]
  end
  ####

  #### AdminGeneral controller
  match '/admin' => 'admin_general#index',
        :as => :admin_general_index,
        :via => :get
  match '/admin/timeline' => 'admin_general#timeline',
        :as => :admin_timeline,
        :via => :get
  match '/admin/debug' => 'admin_general#debug',
        :as => :admin_debug,
        :via => :get
  match '/admin/stats' => 'admin_general#stats',
        :as => :admin_stats,
        :via => :get
  ####

  #### AdminRequest controller
  scope '/admin', :as => 'admin' do
    resources :requests,
      :controller => 'admin_request',
    :except => [:new, :create] do
      post 'move', :on => :member
      post 'generate_upload_url', :on => :member
      post 'hide', :on => :member
      resources :censor_rules,
        :controller => 'admin_censor_rule',
        :only => [:new, :create]
    end
  end
  ####

  #### AdminComment controller
  scope '/admin', :as => 'admin' do
    resources :comments,
      :controller => 'admin_comment',
      :only => [:edit, :update]
  end
  ####

  #### AdminRawEmail controller
  scope '/admin', :as => 'admin' do
    resources :raw_emails,
      :controller => 'admin_raw_email',
      :only => [:show]
  end
  ####

  #### AdminInfoRequestEvent controller
  scope '/admin', :as => 'admin' do
    resources :info_request_events,
      :controller => 'admin_info_request_event',
      :only => [:update]
  end

  #### AdminIncomingMessage controller
  scope '/admin', :as => 'admin' do
    resources :incoming_messages,
      :controller => 'admin_incoming_message',
    :only => [:edit, :update, :destroy] do
      post 'redeliver', :on => :member
    end
    resource :incoming_messages,
      :controller => 'admin_incoming_message',
      :only => [:bulk_destroy] do
        post 'bulk_destroy'
      end
  end
  ####

  #### AdminOutgoingMessage controller
  scope '/admin', :as => 'admin' do
    resources :outgoing_messages,
      :controller => 'admin_outgoing_message',
    :only => [:edit, :update, :destroy] do
      post 'resend', :on => :member
    end
  end
  ####

  #### AdminUser controller
  scope '/admin', :as => 'admin' do
    resources :users,
      :controller => 'admin_user',
    :except => [:new, :create, :destroy] do
      get 'banned', :on => :collection
      get 'show_bounce_message', :on => :member
      post 'clear_bounce', :on => :member
      post 'login_as', :on => :member
      post 'clear_profile_photo', :on => :member
      post 'modify_comment_visibility', :on => :collection
      resources :censor_rules,
        :controller => 'admin_censor_rule',
        :only => [:new, :create]
      end
  end
  ####

  #### AdminTrack controller
  scope '/admin', :as => 'admin' do
    resources :tracks,
      :controller => 'admin_track',
      :only => [:index, :destroy]
  end
  ####

  #### AdminCensorRule controller
  scope '/admin', :as => 'admin' do
    resources :censor_rules,
      :controller => 'admin_censor_rule'
  end

  #### AdminSpamAddresses controller
  scope '/admin', :as => 'admin' do
    resources :spam_addresses,
      :controller => 'admin_spam_addresses',
      :only => [:index, :create, :destroy]
  end
  ####

  #### Api controller
  match '/api/v2/request.json' => 'api#create_request',
        :as => :api_create_request,
        :via => :post

  match '/api/v2/request/:id.json' => 'api#show_request',
        :as => :api_show_request,
        :via => :get
  match '/api/v2/request/:id.json' => 'api#add_correspondence',
        :as => :api_add_correspondence,
        :via => :post
  match '/api/v2/request/:id/update.json' => 'api#update_state',
        :as => :api_update_state,
        :via => :post

  match '/api/v2/body/:id/request_events.:feed_type' => 'api#body_request_events',
        :as => :api_body_request_events,
        :feed_type => '^(json|atom)$'
  ####

  filter :conditionallyprependlocale
end
