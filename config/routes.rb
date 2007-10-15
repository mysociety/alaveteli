# config/routes.rb:
# Mapping URLs to controllers for FOIFA.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: routes.rb,v 1.13 2007-10-15 22:26:38 louise Exp $

ActionController::Routing::Routes.draw do |map|
    # The priority is based upon order of creation: first created -> highest priority.

    # Sample of regular route:
    # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
    # Keep in mind you can assign values other than :controller and :action
    
    map.with_options :controller => 'request' do |request|
      request.connect '/',            :action => 'frontpage'
      request.connect '/list',        :action => 'list'
      request.connect '/index',       :action => 'index' 
      request.connect '/new',         :action => 'new'
      request.connect '/create',      :action => 'create' 
      request.connect '/request/:id', :action => 'show'   
    end

    map.with_options :controller => 'user' do |user|
      user.connect '/signin',     :action => 'signin'
      user.connect '/signup',     :action => 'signup'
      user.connect '/signout',    :action => 'signout'
      user.connect "/user/:name", :action => 'index'
    end

    map.connect "/body/:short_name", :controller => 'body', :action => 'show'

    map.connect '/admin/:action', :controller => 'admin', :action => 'index'
    map.connect '/admin/body/:action/:id', :controller => 'admin_public_body'

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
    #map.connect ':controller/:action/:id.:format'
    #map.connect ':controller/:action/:id'
    # map.connect '/:controller/:action'
end

