# -*- encoding : utf-8 -*-
require 'active_record/associations/builder/association'
require 'active_record/associations/builder/belongs_to'
require 'active_record/associations/builder/has_one'

# Backport https://git.io/v6r9W to Rails 4.0.
#
# Fix bug, when ':dependent => :destroy' violates foreign key constraints.
# See https://github.com/rails/rails/issues/12380 and
# https://github.com/rails/rails/pull/12450
module ActiveRecord::Associations::Builder
  class Association
    def configure_dependency
      check_dependent_options

      if options[:dependent] == :restrict
        ActiveSupport::Deprecation.warn(
          "The :restrict option is deprecated. Please use :restrict_with_exception instead, which " \
          "provides the same functionality."
        )
      end

      add_destroy_callbacks(model, name)
    end

    private

    def check_dependent_options
      unless valid_dependent_options.include? options[:dependent]
        raise ArgumentError, "The :dependent option must be one of #{valid_dependent_options}, but is :#{options[:dependent]}"
      end
    end

    def add_destroy_callbacks(model, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{macro}_dependent_for_#{name}
          association(:#{name}).handle_dependency
        end
      CODE

      model.before_destroy "#{macro}_dependent_for_#{name}"
    end
  end
end

module ActiveRecord::Associations::Builder
  class BelongsTo < SingularAssociation
    private
    def add_destroy_callbacks(model, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{macro}_dependent_for_#{name}
          association(:#{name}).handle_dependency
        end
      CODE

      model.after_destroy "#{macro}_dependent_for_#{name}"
    end
  end
end

module ActiveRecord::Associations::Builder
  class HasOne < SingularAssociation
    private
    def add_destroy_callbacks(model, name)
      super unless options[:through]
    end
  end
end
