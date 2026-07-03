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
  end

  def global?
    censorable_id.nil? && censorable_type.nil?
  end

  def censorable_requests
    censorable&.info_requests || InfoRequest.unscoped
  end
end
