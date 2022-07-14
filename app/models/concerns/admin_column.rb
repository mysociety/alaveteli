module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      def admin_columns
        translated_columns +
          content_columns_names +
          additional_admin_columns -
          non_admin_columns
      end

      def translated_columns
        translates? ? translated_attribute_names.map(&:to_s) : []
      end

      def content_columns_names
        table_exists? ? content_columns.map(&:name) : []
      end

      def additional_admin_columns
        @additional_admin_columns&.map(&:to_s) || []
      end

      def non_admin_columns
        @non_admin_columns&.map(&:to_s) || []
      end
    end
  end

  def for_admin_column(*columns)
    columns = self.class.admin_columns if columns.empty?
    columns.map(&:to_s).each { |name| yield(name, send(name)) }
  end
end
