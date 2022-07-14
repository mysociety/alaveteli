module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      attr_reader :non_admin_columns, :additional_admin_columns

      def all_admin_columns
        translated_columns +
          content_columns.map(&:name) +
          additional_admin_columns
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

    @non_admin_columns = []
    @additional_admin_columns = []
  end

  def for_admin_column(set = :all)
    columns = self.class.admin_column_sets[set]

    reject_non_admin_columns(columns).each do |name|
      yield(name, send(name))
    end
  end

  private

  def reject_non_admin_columns(columns)
    columns.reject { |name| self.class.non_admin_columns.include?(name) }
  end
end
