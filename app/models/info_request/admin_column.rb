module InfoRequest::AdminColumn
  extend ActiveSupport::Concern

  included do
    include ::AdminColumn

    class << self
      def admin_column_sets
        all = all_admin_columns
        { all: all - %w(title url_title) + %w(rejected_incoming_count) }
      end
    end
  end
end
