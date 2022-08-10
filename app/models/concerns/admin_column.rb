module AdminColumn
  extend ActiveSupport::Concern

  class_methods do
    def admin_columns(attrs)
      attrs.each do |set, columns|
        admin_column_sets[set] = columns.map(&:to_s)
      end
    end
  end

  included do
    class << self
      def default_admin_columns
        { all: translated_columns + content_columns.map(&:name),
          minimal: translated_columns + content_columns.map(&:name) }
      end

      def admin_column_sets
        @admin_column_sets ||= default_admin_columns
      end

      def translated_columns
        if translates?
          translated_attribute_names.map(&:to_s)
        else
          []
        end
      end
    end
  end

  def for_admin_column(set = :all)
    columns = self.class.admin_column_sets[set]
    columns.each { |name| yield(name, send(name)) }
  end
end
