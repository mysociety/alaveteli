##
# Module with helper methods for controllers which allows them to respond
# differently when a public token param exists.
#
# This this is done primarily by redefining the current ability method.
#
module PublicTokenable
  extend ActiveSupport::Concern

  included do
    helper_method :public_token
  end

  private

  def public_token
    params[:public_token]
  end

  def current_ability
    @current_ability ||= Ability.new(
      current_user, public_token: public_token.present?
    )
  end
end
