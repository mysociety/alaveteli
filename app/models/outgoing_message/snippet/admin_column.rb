module OutgoingMessage::Snippet::AdminColumn
  extend ActiveSupport::Concern

  included do
    include ::AdminColumn

    class << self
      def admin_column_sets
        all = all_admin_columns
        { all: all - %w(name) }
      end
    end
  end
end
