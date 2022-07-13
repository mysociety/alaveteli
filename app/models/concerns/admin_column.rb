module AdminColumn
  extend ActiveSupport::Concern

  included do
    class << self
      attr_reader :non_admin_columns, :additional_admin_columns
    end

    @non_admin_columns = []
    @additional_admin_columns = []
  end

  def for_admin_column
    columns = translated_columns +
              self.class.content_columns.map(&:name) +
              self.class.additional_admin_columns


    reject_non_admin_columns(columns).each do |name|
      yield(name, send(name))
    end
  end

  private

  def reject_non_admin_columns(columns)
    columns.reject { |name| self.class.non_admin_columns.include?(name) }
  end

  def translated_columns
    if self.class.translates?
      self.class.translated_attribute_names.map(&:to_s)
    else
      []
    end
  end

end
