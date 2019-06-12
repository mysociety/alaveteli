# frozen_string_literal: true

# Fixes `ThreadError: already initialized` errors when running Rails 4
# controller specs under Ruby 2.6
#
#
# See:
#   https://github.com/rails/rails/issues/34790#issuecomment-450502805

if RUBY_VERSION >= '2.6.0' && Rails.pre_version5?
  class ActionController::TestResponse < ActionDispatch::TestResponse
    def recycle!
      # hack to avoid MonitorMixin double-initialize error:
      @mon_mutex_owner_object_id = nil
      @mon_mutex = nil
      initialize
    end
  end
end
