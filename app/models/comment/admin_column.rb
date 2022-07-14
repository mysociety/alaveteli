module Comment::AdminColumn
  extend ActiveSupport::Concern

  included do
    include ::AdminColumn

    class << self
      def admin_column_sets
        {
          all: all_admin_columns,
          minimal: %w(body visible created_at updated_at)
        }
      end
    end
  end
end
