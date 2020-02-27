# -*- encoding : utf-8 -*-
module MessageProminence
  extend ActiveSupport::Concern

  included do
    validates_inclusion_of :prominence, in: prominence_states
  end

  def indexed_by_search?
    is_public?
  end

  def is_public?
    prominence == 'normal'
  end

  module ClassMethods
    def prominence_states
      %w[normal hidden requester_only]
    end
  end
end
