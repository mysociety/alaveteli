module PublicBody::AdminColumn
  extend ActiveSupport::Concern

  included do
    include ::AdminColumn

    class << self
      def admin_column_sets
        all = all_admin_columns
        { all: all - %w(name last_edit_editor) }
      end
    end
  end
end
