module InfoRequestEvent::AdminColumn
  extend ActiveSupport::Concern

  included do
    include ::AdminColumn

    class << self
      def admin_column_sets
        {
          all: all_admin_columns,
          minimal: %w(event_type params_yaml created_at)
        }
      end
    end
  end
end
