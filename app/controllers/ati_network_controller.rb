# Content pages related to our wider Access to Information Network and Community
# of Practice
class AtiNetworkController < ApplicationController
  # Set `AtiNetworkController.showcase_enabled = false` in your theme to disable
  # the showcase page.
  class_attribute :showcase_enabled, default: true

  before_action :check_showcase_enabled, only: :showcase

  def showcase
    @title =
      _('Access to Information around the world: high-impact journalism, ' \
        'campaigns and research from local communities to the international ' \
        'stage.')
  end

  private

  def check_showcase_enabled
    raise ActiveRecord::RecordNotFound unless showcase_enabled?
  end
end
