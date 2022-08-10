module AdminColumn
  extend ActiveSupport::Concern

  class_methods do
    def admin_columns(columns = default_admin_columns)
      @admin_columns = columns.map(&:to_s)
    end
  end

  included do
    class << self
      def default_admin_columns
        translated_columns + content_columns.map(&:name)
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

  def for_admin_column(*columns)
    columns = columns.empty? ? self.class.admin_columns : columns
    columns.map(&:to_s).each { |name| yield(name, send(name)) }
  end
end
