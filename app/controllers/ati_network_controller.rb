# Content pages related to our wider Access to Information Network and Community
# of Practice
class AtiNetworkController < ApplicationController
  def showcase
    @title =
      _('Access to Information around the world: high-impact journalism, ' \
        'campaigns and research from local communities to the international ' \
        'stage.')
  end
end
