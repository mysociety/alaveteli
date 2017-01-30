class Ability
  include CanCan::Ability
  include AlaveteliFeatures::Helpers

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    # Updating request status
    can :update_request_state, InfoRequest do |request|
      self.class.can_update_request_state?(user, request)
    end

    # Viewing messages with prominence
    can :read, [IncomingMessage, OutgoingMessage] do |msg|
      self.class.can_view_with_prominence?(msg.prominence,
                                           msg.info_request,
                                           user)
    end

    # Viewing requests with prominence
    can :read, InfoRequest do |request|
      self.class.can_view_with_prominence?(request.prominence, request, user)
    end

    # Accessing alaveteli professional
    if feature_enabled? :alaveteli_pro
      if user && (user.super? || user.pro?)
        can :access, :alaveteli_pro
      end
    end
  end

  private

  def self.can_update_request_state?(user, request)
    (user && request.is_old_unclassified?) || request.is_owning_user?(user)
  end

  def self.can_view_with_prominence?(prominence, info_request, user)
    if info_request.embargo
      case prominence
      when 'hidden'
        User.view_hidden_and_embargoed?(user)
      when 'requester_only'
        info_request.is_actual_owning_user?(user) || User.view_hidden_and_embargoed?(user)
      else
        info_request.is_actual_owning_user?(user) || User.view_embargoed?(user)
      end
    else
      case prominence
      when 'hidden'
        User.view_hidden?(user)
      when 'requester_only'
        info_request.is_actual_owning_user?(user) || User.view_hidden?(user)
      else
        true
      end
    end
  end
end
