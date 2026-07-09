module LowPriorityWorker
  extend ActiveSupport::Concern

  included do
    queue_as do
      Current.bot_request ? :bulk_processor : :default
    end
  end
end
