module User::AdminColumn
  extend ActiveSupport::Concern

  included do
    include ::AdminColumn

    class << self
      def admin_column_sets
        {
          all: all_admin_columns,
          minimal: %w(created_at updated_at email_confirmed)
        }
      end
    end
  end
end
