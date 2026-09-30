# CensorRules can be associated with various record types via a polymorphic
# relationship. If a censorable is not defined, the CensorRule is considered
# "global", meaning it will apply to all InfoRequest records.
module CensorRule::Polymorphic
  extend ActiveSupport::Concern

  included do
    belongs_to :censorable, polymorphic: true, optional: true

    scope :info_request, -> { where(censorable_type: 'InfoRequest') }
    scope :public_body, -> { where(censorable_type: 'PublicBody') }
    scope :user, -> { where(censorable_type: 'User') }
    scope :global, -> { where(censorable_id: nil, censorable_type: nil) }

    # Rules that apply to any of the given requests, whether attached to the
    # requests themselves, their users or public bodies, or global
    scope :applicable_to_requests, ->(info_requests) {
      user_ids = info_requests.select(:user_id)
      public_body_ids = info_requests.select(:public_body_id)

      global.
        or(where(censorable: info_requests)).
        or(user.where(censorable_id: user_ids)).
        or(public_body.where(censorable_id: public_body_ids))
    }
  end

  def global?
    censorable_id.nil? && censorable_type.nil?
  end

  def censorable_requests
    censorable&.info_requests || InfoRequest.unscoped
  end
end
