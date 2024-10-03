class ApplicationRecord < ActiveRecord::Base
  include ConfigHelper

  include AdminColumn

  self.abstract_class = true

  def self.admin_title
    name
  end

  def self.belongs_to(name, scope = nil, **options)
    if options.key?(:via)
      via = options.delete(:via)
      polymorphic_association = reflect_on_association(via)

      unless polymorphic_association&.polymorphic?
        raise ArgumentError, "Association #{via} must be polymorphic"
      end

      options[:foreign_key] ||= polymorphic_association.foreign_key
      options[:class_name] ||= name.to_s.classify

      scope = -> {
        where(
          polymorphic_association.active_record.table_name => {
            polymorphic_association.foreign_type => options[:class_name]
          }
        )
      }
    end

    super(name, scope, **options)
  end
end
