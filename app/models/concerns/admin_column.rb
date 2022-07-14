module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      def all_admin_columns
        translated_columns + content_columns.map(&:name)
      end

      def admin_column_sets
        { all: all_admin_columns }
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
