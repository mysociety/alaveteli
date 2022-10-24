module MessageProminence
  extend ActiveSupport::Concern

  included do
    strip_attributes only: [:prominence_reason]
    validates_inclusion_of :prominence, in: self.prominence_states
  end

  def indexed_by_search?
    is_public?
  end

  def is_public?
    prominence == 'normal'
  end

  module ClassMethods
    def prominence_states
      %w(normal requester_only hidden)
    end
  end
end
