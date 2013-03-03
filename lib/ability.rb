module Ability
  def self.can_update_request_state?(user, request)
    (user && request.is_old_unclassified?) || request.is_owning_user?(user)
  end
end