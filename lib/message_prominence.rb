# -*- encoding : utf-8 -*-
module MessageProminence

  def has_prominence
    send :include, InstanceMethods
    cattr_accessor :prominence_states
    self.prominence_states = ['normal', 'hidden','requester_only']
    validates_inclusion_of :prominence, :in => self.prominence_states
  end

  module InstanceMethods

    def user_can_view?(user)
      Ability.can_view_with_prominence?(self.prominence, self.info_request, user)
    end

    def indexed_by_search?
      self.prominence == 'normal'
    end

    def all_can_view?
      self.prominence == 'normal'
    end

  end
end
