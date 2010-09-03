
module Interlock
  module Finders
    def self.included(klass)
      class << klass
        alias_method :find_via_db, :find
        remove_method :find
      end
      
      klass.extend ClassMethods
    end
    
    module ClassMethods

      #
      # Cached find. 
      # 
      # Any other options besides ids short-circuit the cache.
      #    
      def find(*args)
        return find_via_db(*args) if args.last.is_a? Hash or args.first.is_a? Symbol
        ids = args.flatten.compact.uniq
        return find_via_db(ids) if ids.blank? 
      
        records = find_via_cache(ids, true)

        if ids.length > 1 or args.first.is_a?(Array)
          records
        else
          records.first
        end      
      
      end
    
      #
      # Cached find_by_id. Short-circuiting works the same as find.
      #
      def find_by_id(*args)
        return method_missing(:find_by_id, *args) if args.last.is_a? Hash
        find_via_cache(args, false).first
      end
    
      #
      # Cached find_all_by_id. Ultrasphinx uses this. Short-circuiting works the same as find.
      #
      def find_all_by_id(*args)
        return method_missing(:find_all_by_id, *args) if args.last.is_a? Hash
        find_via_cache(args, false)
      end
    
      #
      # Build the model cache key for a particular id.
      #
      def caching_key(id)
        Interlock.caching_key(
          self.base_class.name,
          "find",
          id,
          "default"
        )
      end

      def finder_ttl
        0
      end

      private

      def find_via_cache(ids, should_raise) #:doc:
        results = []

        ordered_keys_to_ids = ids.flatten.map { |id| [caching_key(id), id.to_i] }
        keys_to_ids = Hash[*ordered_keys_to_ids.flatten]

        records = {}
      
        if ActionController::Base.perform_caching
          load_from_local_cache(records, keys_to_ids)
          load_from_memcached(records, keys_to_ids)
        end
      
        load_from_db(records, keys_to_ids)
      
        # Put them in order
      
        ordered_keys_to_ids.each do |key, |
          record = records[key]
          raise ActiveRecord::RecordNotFound, "Couldn't find #{self.name} with ID=#{keys_to_ids[key]}" if should_raise and !record
          results << record
        end
     
        # Don't return Nil objects, only the found records
        results.compact
      end
    
      def load_from_local_cache(current, keys_to_ids) #:doc:            
        # Load from the local cache      
        records = {}
        keys_to_ids.each do |key, |
          record = Interlock.local_cache.read(key, nil)
          records[key] = record if record
        end      
        current.merge!(records)        
      end

      def load_from_memcached(current, keys_to_ids) #:doc:
        # Drop to memcached if necessary
        if current.size < keys_to_ids.size
          records = {}
          missed = keys_to_ids.reject { |key, | current[key] }      
        
          records = CACHE.get_multi(*missed.keys)
        
          # Set missed to the caches
          records.each do |key, value|
            Interlock.say key, "is loading from memcached", "model"
            Interlock.local_cache.write(key, value, nil)
          end
                
          current.merge!(records)
        end    
      end

      def load_from_db(current, keys_to_ids) #:doc:
        # Drop to db if necessary
        if current.size < keys_to_ids.size
          missed = keys_to_ids.reject { |key, | current[key] }
          ids_to_keys = keys_to_ids.invert

          # Load from the db
          ids_to_find = missed.values
          if ids_to_find.length > 1
            records = send("find_all_by_#{primary_key}".to_sym, ids_to_find, {})
          else
            records = [send("find_by_#{primary_key}".to_sym, ids_to_find.first, {})].compact # explicitly just look for one if that's all that's needed
          end

          records = Hash[*(records.map do |record|
            [ids_to_keys[record.id], record]
          end.flatten)]
        
          # Set missed to the caches
          records.each do |key, value|
            Interlock.say key, "is loading from the db", "model"
            Interlock.local_cache.write(key, value, nil)
            CACHE.set key, value, value.class.finder_ttl unless Interlock.config[:disabled]
          end
        
          current.merge!(records)
        end    
      end
    end
  end # Finders
end # Interlock
  
