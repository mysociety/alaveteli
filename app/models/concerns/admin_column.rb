module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      def admin_columns(exclude: nil, include: nil)
        @excluded_admin_columns = exclude || @excluded_admin_columns
        @included_admin_columns = include || @included_admin_columns
        sorted_columns
      end

      # Ensure prominence_reason immediately follows prominence
      def sorted_columns
        return all_columns unless prominenceable_admin_columns?
        index = all_columns.index('prominence') + 1
        all_columns.insert(index, all_columns.delete('prominence_reason'))
      end

      def prominenceable_admin_columns?
        all_columns.prominence? && all_columns.prominence_reason?
      end

      def all_columns
        (translated_columns +
          content_columns_names +
          included_admin_columns -
          excluded_admin_columns).inquiry
      end

      def translated_columns
        translates? ? translated_attribute_names.map(&:to_s) : []
      end

      def content_columns_names
        table_exists? ? content_columns.map(&:name) : []
      end

      def included_admin_columns
        @included_admin_columns&.map(&:to_s) || []
      end

      def excluded_admin_columns
        @excluded_admin_columns&.map(&:to_s) || []
      end
    end
  end

  def for_admin_column(*columns)
    columns = self.class.admin_columns if columns.empty?
    columns.map(&:to_s).each { |name| yield(name, send(name)) }
  end
end
