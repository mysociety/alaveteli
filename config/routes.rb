# config/routes.rb:
# Mapping URLs to controllers for FOIFA.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: routes.rb,v 1.7 2007-10-08 14:58:28 francis Exp $

ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action
  map.connect "/new/:action", :controller => 'new', :action => 'index'

  map.connect '/admin/:action', :controller => 'admin', :action => 'index'
  map.connect '/admin/body/:action/:id', :controller => 'admin_public_body'

  map.connect "/:action/:id", :controller => 'frontpage'

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
end

