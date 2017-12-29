# -*- encoding : utf-8 -*-
module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      attr_reader :non_admin_columns
    end

    @non_admin_columns = []
  end

  def for_admin_column
    reject_non_admin_columns(self.class.content_columns).each do |column|
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
end
