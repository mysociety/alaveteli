# -*- encoding : utf-8 -*-
# Rails 4 introduces a bug that causes customised counter_cache code to be
# fired twice as described here:
# https://github.com/rails/rails/issues/10865#issuecomment-21373642
#
# This is a 4.0-specific fix adapted from https://github.com/rails/rails/pull/14849/files

module ActiveRecord

  module Associations

    class BelongsToAssociation < SingularAssociation #:nodoc:

      # this is will need to changed when upgrading to Rails 4.1 - the key thing
      # is not to call update_counters(record)
      def replace(record)
        raise_on_type_mismatch!(record) if record

        replace_keys(record)
        set_inverse_instance(record)

        @updated = true if record

        self.target = record
      end

      def decrement_previous_counters # :nodoc:
        with_cache_name { |name| decrement_previous_counter name }
      end

      # To be overrided by subclasses
      def changed?
        owner.attribute_changed?(reflection.foreign_key)
      end

      private

      def decrement_previous_counter(counter_cache_name)
        if scope = previous_target_scope
          scope.decrement_counter(counter_cache_name)
        end
      end

      def previous_target_scope
        if klass = previous_klass
          primary_key = reflection.association_primary_key(klass)
          klass.where(primary_key => owner.attribute_was(reflection.foreign_key))
        end
      end

      def previous_klass
        klass
      end

    end

    class BelongsToPolymorphicAssociation < BelongsToAssociation #:nodoc:

      def changed?
        super || owner.attribute_changed?(reflection.foreign_type)
      end

      private

      def previous_klass
        owner.attribute_was(reflection.foreign_type).try(:constantize)
      end

    end

    module Builder

      class BelongsTo < SingularAssociation #:nodoc:

        def self.define_callbacks(model, reflection)
          super
          mark_counter_cache_readonly(model, reflection) if reflection.options[:counter_cache]
          add_touch_callbacks(model, reflection)         if reflection.options[:touch]
        end

        private

        def self.mark_counter_cache_readonly(model, reflection)
          cache_column = reflection.counter_cache_column
          klass = reflection.class_name.safe_constantize
          klass.attr_readonly cache_column if klass && klass.respond_to?(:attr_readonly)
        end

      end

    end

  end

  module CounterCache

    module ClassMethods

      def update_counters(id, counters)
        unscoped.where(primary_key => id).update_counters(counters)

        # Increment a numeric field by one, via a direct SQL update.
        id
      end

      def _update_record(*)
        each_counter_cached_associations do |association|
          if association.changed? && !new_record?
            column = association.reflection.foreign_key
            foreign_key_was = attribute_was(column)
            foreign_key = attribute(column)

            affected_rows = self.class.where(id: id, column => foreign_key_was).update_all(column => foreign_key)

            if affected_rows > 0
              association.increment_counters if foreign_key
              association.decrement_previous_counters if foreign_key_was
            end
          end
        end

        super
      end

    end

  end

  module NullRelation # :nodoc:

    def update_counters(_updates)
      0
    end

    def decrement_counter(_name)
      0
    end

    def increment_counter(_name)
      0
    end

  end

  class Relation

    def update_counters(counters)
      updates = counters.map do |counter_name, value|
        operator = value < 0 ? '-' : '+'
        quoted_column = connection.quote_column_name(counter_name)
        "#{quoted_column} = COALESCE(#{quoted_column}, 0) #{operator} #{value.abs}"
      end

      update_all updates.join(', ')
    end

    def decrement_counter(counter_name)
      update_counters(counter_name => -1)
    end

    def increment_counter(counter_name)
      update_counters(counter_name => 1)
    end

  end

end
