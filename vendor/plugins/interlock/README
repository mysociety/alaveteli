
Interlock

A Rails plugin for maintainable and high-efficiency caching.

== License

Copyright 2007, 2008 Cloudburst, LLC. Licensed under the AFL 3. See the included LICENSE file. Portions copyright 2006 Chris Wanstrath and used with permission.

The public certificate for the gem is here[http://blog.evanweaver.com/files/evan_weaver-original-public_cert.pem]. 

If you use this software, please {make a donation}[http://blog.evanweaver.com/donate/], or {recommend Evan}[http://www.workingwithrails.com/person/7739-evan-weaver] at Working with Rails.

== Requirements

* memcached (http://www.danga.com/memcached)
* memcache-client gem
* Rails 2.1

== Features

Interlock is an intelligent fragment cache for Rails. 

It works by making your view fragments and associated controller blocks march along together. If a fragment is fresh, the controller behavior won't run. This eliminates duplicate effort from your request cycle. Your controller blocks run so infrequently that you can use regular ActiveRecord finders and not worry about object caching at all.

Invalidations are automatically tracked based on the model lifecyle, and you can scope any block to an arbitrary level. Interlock also caches <tt>content_for</tt> calls, unlike regular Rails, and can optionally cache simple finders.

Interlock uses a tiered caching layer so that multiple lookups of a key only hit memcached once per request.

== Installation
  
First, compile and install memcached itself. Get a memcached server running.

You also need either <tt>memcache-client</tt> or {memcached}[http://blog.evanweaver.com/files/doc/fauna/memcached]:
  sudo gem install memcache-client

Then, install the plugin:
  script/plugin install git://github.com/fauna/interlock.git
  
Lastly, configure your Rails app for memcached by creating a <tt>config/memcached.yml</tt> file. The format is compatible with Cache_fu:

  defaults:
    namespace: myapp
    sessions: false
    client: memcache-client
  development:
    servers: 
      - 127.0.0.1:11211 # Default host and port
  production:
    servers:
      - 10.12.128.1:11211
      - 10.12.128.2:11211
      
Now you're ready to go.

Note that if you have the {memcached}[http://blog.evanweaver.com/files/doc/fauna/memcached] client, you can use <tt>client: memcached</tt> for better performance.
 
== Usage

Interlock provides two similar caching methods: <tt>behavior_cache</tt> for controllers and <tt>view_cache</tt> for views. They both accept an optional list or hash of model dependencies, and an optional <tt>:tag</tt> keypair. <tt>view_cache</tt> also accepts a <tt>:ttl</tt> keypair.

The simplest usage doesn't require any parameters. In the controller:

  class ItemsController < ActionController::Base
  
    def slow_action
      behavior_cache do
        @items = Item.find(:all, :conditions => "be slow")
      end
    end
    
  end
  
Now, in the view, wrap the largest section of ERB you can find that uses data from <tt>@items</tt> in a <tt>view_cache</tt> block. No other part of the view can refer to <tt>@items</tt>, because <tt>@items</tt> won't get set unless the cache is stale.

  <% @title = "My Sweet Items" %>

  <% view_cache do %>
    <% @items.each do |item| %>
      <h1><%= item.name %></h1>
    <% end %>
  <% end %>
  
You have to do them both.

This automatically registers a caching dependency on Item for <tt>slow_action</tt>. The controller block won't run if the <tt>slow_action</tt> view fragment is fresh, and the view fragment will only get invalidated when an Item is changed. 

You can use multiple instance variables in one block, of course. Just make sure the <tt>behavior_cache</tt> provides whatever the <tt>view_cache</tt> uses.

See ActionController::Base and ActionView::Helpers::CacheHelper for more details.

== Caching finders

Interlock 1.3 adds the ability to cache simple finder lookups. Add this line in <tt>config/memcached.yml</tt>:

  with_finders: true
  
Now, whenever you call <b>find</b>, <b>find_by_id</b>, or <b>find_all_by_id</b> with a single id or an array of ids, the cache will be used. The cache key for each record invalidates when the record is saved or destroyed. Memcached's multiget mode is used for maximum performance.

If you pass any parameters other than ids, or use dynamic finders, the cache will not be used. This means that <tt>:include</tt> works as expected and does not require complicated invalidation. 

See Interlock::Finders for more.

== Notes

You will not see any actual cache reuse in development mode unless you set <tt>config.action_controller.perform_caching = true</tt> in <tt>config/environments/development.rb</tt>.

<b>If you have custom <tt>render</tt> calls in the controller, they must be outside the <tt>behavior_cache</tt> blocks.</b> No exceptions. For example:

  def profile
    behavior_cache do
      @items = Item.find(:all, :conditions => "be slow")
    end
    render :action => 'home'
  end

You can write custom invalidation rules if you really want to, but try hard to avoid it; it has a significant cost in long-term maintainability.

Also, Interlock obeys the <tt>ENV['RAILS_ASSET_ID']</tt> setting, so if you need to blanket-invalidate all your caches, just change <tt>RAILS_ASSET_ID</tt> (for example, you could have it increment on every deploy).

== Further resources

* http://blog.evanweaver.com/articles/2007/12/13/better-rails-caching/
* http://www.socialtext.net/memcached/index.cgi?faq

== Reporting problems

The support forum is here[http://github.com/fauna/interlock/issues].

Patches and contributions are very welcome. Please note that contributors are required to assign copyright for their additions to Cloudburst, LLC. 
