# Handle updating of request content in response to CensorRule modifications
module CensorRule::Expiry
  extend ActiveSupport::Concern

  included do
    after_commit :expire_requests
  end

  def expire_requests
    if censorable
      censorable.expire_requests
    else
      InfoRequest::ExpireJob.perform_later(InfoRequest, :all)
    end
  end
end
