
module ActionView #:nodoc:
  class Base #:nodoc:
    attr_accessor :cached_content_for
  end

  module Helpers #:nodoc:
    module CacheHelper 
     
=begin rdoc     

<tt>view_cache</tt> marks a corresponding view block for caching. It accepts <tt>:tag</tt> and <tt>:ignore</tt> keys for explicit scoping, as well as a <tt>:ttl</tt> key and a <tt>:perform</tt> key. 

You can specify dependencies in <tt>view_cache</tt> if you really want to. Note that unlike <tt>behavior_cache</tt>, <tt>view_cache</tt> doesn't set up any default dependencies.

Nested <tt>view_cache</tt> blocks work fine. You would only need to nest if you had a slowly invalidating block contained in a more quickly invalidating block; otherwise there's no benefit.

Finally, caching <tt>content_for</tt> within a <tt>view_cache</tt> works, unlike regular Rails. It even works in nested caches.

== Setting a TTL

Use the <tt>:ttl</tt> key to specify a maximum time-to-live, in seconds:

  <% view_cache :ttl => 5.minutes do %>
  <% end %>

Note that the cached item is not guaranteed to live this long. An invalidation rule could trigger first, or memcached could eject the item early due to the LRU.

== View caching without action caching

It's fine to use a <tt>view_cache</tt> block without a <tt>behavior_cache</tt> block. For example, to mimic regular fragment cache behavior, but take advantage of memcached's <tt>:ttl</tt> support, call:

  <% view_cache :ignore => :all, :tag => 'sidebar', :ttl => 5.minutes do %>
  <% end %>  
  
== Dependencies, scoping, and other options

See ActionController::Base for explanations of the rest of the options. The <tt>view_cache</tt> and <tt>behavior_cache</tt> APIs are identical except for setting the <tt>:ttl</tt>, which can only be done in the view, and the default dependency, which is only set by <tt>behavior_cache</tt>.

=end     
     def view_cache(*args, &block)       
       # conventional_class = begin; controller.controller_name.classify.constantize; rescue NameError; end
       options, dependencies = Interlock.extract_options_and_dependencies(args, nil)  

       key = controller.caching_key(options.value_for_indifferent_key(:ignore), options.value_for_indifferent_key(:tag))      
       
       if options[:perform] == false || Interlock.config[:disabled]
         # Interlock.say key, "is not cached"
         block.call
       else       
         Interlock.register_dependencies(dependencies, key)

         # Interlock.say key, "is rendering"

         @cached_content_for, previous_cached_content_for = {}, @cached_content_for

         cache key, :ttl => (options.value_for_indifferent_key(:ttl) or Interlock.config[:ttl]), &block
         
         # This is tricky. If we were already caching content_fors in a parent block, we need to 
         # append the content_fors set in the inner block to those already set in the outer block. 
         if previous_cached_content_for
           @cached_content_for.each do |key, value|
             previous_cached_content_for[key] = "#{previous_cached_content_for[key]}#{value}"
           end
         end
         
         # Restore the cache state
         @cached_content_for = previous_cached_content_for         
       end
     end
     
    #:stopdoc:
    alias :caching :view_cache # Deprecated
    #:startdoc:
     
    end

  
    module CaptureHelper
      #
      # Override content_for so we can cache the instance variables it sets along with the fragment.
      #
      def content_for(name, content = nil, &block)
        ivar = "@content_for_#{name}"
        existing_content = instance_variable_get(ivar).to_s
        this_content = (block_given? ? capture(&block) : content)
        
        # If we are in a view_cache block, cache what we added to this instance variable
        if @cached_content_for
          @cached_content_for[name] = "#{@cached_content_for[name]}#{this_content}"
        end
        
        instance_variable_set(ivar, existing_content + this_content)
      end    
    end

  end
end
