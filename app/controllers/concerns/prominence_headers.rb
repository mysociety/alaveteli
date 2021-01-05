##
# Set any response headers related to prominence.
#
module ProminenceHeaders
  extend ActiveSupport::Concern

  included do
    before_action :set_prominence_headers
  end

  def with_prominence
    raise NotImplementedError
  end

  private

  def set_prominence_headers
    return unless with_prominence
    send("set_#{ with_prominence.prominence }_headers")
  end

  def set_normal_headers
  end

  def set_backpage_headers
    headers['X-Robots-Tag'] = 'noindex'
  end

  def set_requester_only_headers
  end

  def set_hidden_headers
  end
end
