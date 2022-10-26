class Ability
  include CanCan::Ability
  include AlaveteliFeatures::Helpers

  attr_reader :user, :project, :public_token

  def self.guest(*args)
    new(nil, *args)
  end

  def initialize(user, project: nil, public_token: false)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.is_admin?
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

    @user = user
    @project = project
    @public_token = public_token

    # Updating request status
    can :update_request_state, InfoRequest do |request|
      can_update_request_state?(request)
    end

    # Viewing requests, messages & attachments as Pro admin
    if user&.view_hidden_and_embargoed?
      can :_read, InfoRequest
      can :_read, OutgoingMessage
      can :_read, IncomingMessage
      can :_read, FoiAttachment
    end

    # Viewing requests, messages & attachments as admin
    if user&.view_hidden?
      can :_read, InfoRequest.not_embargoed
      can :_read, OutgoingMessage, info_request: InfoRequest.not_embargoed
      can :_read, IncomingMessage, info_request: InfoRequest.not_embargoed
      can :_read, FoiAttachment, incoming_message: { info_request: InfoRequest.not_embargoed }
    end

    # Viewing requests, messages & attachments with public prominence
    can :_read, InfoRequest.not_embargoed, prominence: %w[normal backpage]
    can :_read, OutgoingMessage, prominence: 'normal'
    can :_read, IncomingMessage, prominence: 'normal'
    can :_read, FoiAttachment, prominence: 'normal'

    if user
      # Viewing their own embargoed requests with public prominence
      can :_read, InfoRequest.embargoed, user: user, prominence: %w[normal backpage]

      # Viewing their own request, messages & attachments with requester only prominence
      can :_read, InfoRequest.not_embargoed, user: user, prominence: 'requester_only'
      can :_read, InfoRequest.embargoed, user: user, prominence: 'requester_only'
      can :_read, OutgoingMessage, info_request: { user: user }, prominence: 'requester_only'
      can :_read, IncomingMessage, info_request: { user: user }, prominence: 'requester_only'
      can :_read, FoiAttachment, incoming_message: { info_request: { user: user } }, prominence: 'requester_only'
    end

    # Reading attachments with prominence
    can :read, FoiAttachment do |attachment|
      can?(:_read, attachment) && can?(:read, attachment.incoming_message)
    end

    # Reading messages with prominence
    can :read, [IncomingMessage, OutgoingMessage] do |message|
      can?(:_read, message) && can?(:read, message.info_request)
    end

    # Reading requests with prominence or via a project or public token
    can :read, InfoRequest do |info_request|
      can?(:_read, info_request) ||
        project&.member?(user) ||
        public_token
    end

    can :manage, OutgoingMessage::Snippet do |request|
      user && user.is_admin?
    end

    # Viewing batch requests
    can :read, InfoRequestBatch do |batch_request|
      if batch_request.embargo_duration
        user && (user == batch_request.user || user&.view_embargoed?)
      else
        true
      end
    end

    # Downloading batch requests
    can :download, InfoRequestBatch do |batch_request|
      user && user == batch_request.user && user.is_pro?
    end

    # Updating batch requests
    can :update, InfoRequestBatch do |batch_request|
      if batch_request.embargo_duration
        user && (user.is_pro_admin? ||
                 (user == batch_request.user && user.is_pro?))
      else
        user && requester_or_admin?(batch_request)
      end
    end

    # Removing batch request embargoes
    can :destroy_embargo, InfoRequestBatch do |batch_request|
      if batch_request.embargo_duration
        user && (user == batch_request.user || user.is_pro_admin?)
      else
        user && requester_or_admin?(batch_request)
      end
    end

    if feature_enabled? :alaveteli_pro
      # Accessing alaveteli professional
      if user && (user.is_pro_admin? || user.is_pro?)
        can :access, :alaveteli_pro
      end

      # Creating embargoes
      can :create_embargo, InfoRequest do |info_request|
        user && info_request.user &&
          info_request.user.is_pro? &&
          (user.is_pro_admin? || user == info_request.user) &&
          !info_request.embargo &&
          info_request.info_request_batch_id.nil?
      end

      # Extending embargoes
      can :update, AlaveteliPro::Embargo do |embargo|
        user && (user.is_pro_admin? ||
                 user == embargo.info_request.user && user.is_pro?)
      end

      # Removing embargoes
      can :destroy, AlaveteliPro::Embargo do |embargo|
        user && (user == embargo.info_request.user || user.is_pro_admin?)
      end
    end

    can :admin, AlaveteliPro::Embargo if user && user.is_pro_admin?

    can :admin, InfoRequest do |info_request|
      if info_request.embargo
        user && user.is_pro_admin?
      else
        user && user.is_admin?
      end
    end

    can :create_citation, InfoRequest do |info_request|
      user && (user.is_admin? || user.is_pro? || info_request.user == user)
    end

    can :share, InfoRequest do |info_request|
      info_request.embargo &&
        (user&.is_pro_admin? || info_request.is_actual_owning_user?(user))
    end

    can :admin, Comment do |comment|
      if comment.info_request.embargo
        user && user.is_pro_admin?
      else
        user && user.is_admin?
      end
    end

    can :login_as, User do |target_user|
      if user == target_user
        false
      elsif target_user.is_pro? || target_user.is_pro_admin?
        user && user.is_pro_admin?
      else
        user && user.is_admin?
      end
    end

    if feature_enabled? :alaveteli_pro
      if user && user.is_pro_admin?
        can :read, :api_key
      end
    else
      if user && user.is_admin?
        can :read, :api_key
      end
    end

    if feature_enabled? :projects
      can :read, Project do |target_project|
        user && (user.is_pro_admin? || target_project.member?(user))
      end

      can :remove_contributor, User do |contributor|
        user && project.contributor?(contributor) &&
          (project.owner?(user) || user == contributor)
      end

      can :download, Project do |target_project|
        user && (user.is_pro_admin? || target_project.owner?(user))
      end
    end
  end

  private

  def can_update_request_state?(request)
    (user && request.is_old_unclassified?) || request.is_owning_user?(user) ||
      (project && project.info_request?(request) && project.member?(user))
  end

  def requester_or_admin?(request)
    user == request.user || user.is_admin?
  end
end
