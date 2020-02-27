# -*- encoding : utf-8 -*-
module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      attr_reader :non_admin_columns

      def additional_admin_columns
        columns.select { |c| @additional_admin_columns.include?(c.name) }
      end
    end

    @non_admin_columns = []
    @additional_admin_columns = []
  end

  def for_admin_column
    columns = translated_columns +
              self.class.content_columns +
              self.class.additional_admin_columns

    reject_non_admin_columns(columns).each do |column|
      yield(column.name.humanize,
            send(column.name),
            column.type.to_s,
            column.name)
    end
  end

  private

  def reject_non_admin_columns(columns)
    columns.reject { |c| self.class.non_admin_columns.include?(c.name) }
  end

  def translated_columns
    if self.class.translates?
      translated_attrs = self.class.translated_attribute_names.map(&:to_s)
      self.class::Translation.content_columns.
        select { |c| translated_attrs.include?(c.name) }
    else
      []
    end
  end
end
