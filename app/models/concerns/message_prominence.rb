module MessageProminence

  extend ActiveSupport::Concern

  included do
    validates_inclusion_of :prominence, :in => self.prominence_states
  end

  def indexed_by_search?
    is_public?
  end

  def is_public?
    self.prominence == 'normal'
  end

  module ClassMethods
    def prominence_states
      ['normal', 'hidden','requester_only']
    end
  end

end
