# -*- encoding : utf-8 -*-
module Ability
  def self.can_update_request_state?(user, request)
    (user && request.is_old_unclassified?) || request.is_owning_user?(user)
  end

  def self.can_view_with_prominence?(prominence, info_request, user)
      if prominence == 'hidden'
          return User.view_hidden?(user)
      end
      if prominence == 'requester_only'
          return info_request.is_owning_user?(user)
      end
      return true
  end

end
