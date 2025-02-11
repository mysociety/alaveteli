##
# This module provides email sending ability control for mailers. It allows
# mailers to check whether email delivery is permitted based on user
# permissions or other criteria.
#
# Key functionality:
# - Wraps mail sending with permission checking
# - Extracts mailer name and action for permission lookup
# - Builds ability instance with mailer context variables
#
module CheckMailerAbility
  extend ActiveSupport::Concern

  def mail_user(user, **headers)
    @user = user

    mail = super
    mail.perform_deliveries = can_send?
    mail
  end

  def can_send?
    ability.can?(:receive, name)
  end

  def name
    [mailer_name.underscore, action_name].join('#')
  end

  def ability
    @ability ||= MailerAbility.new(@user, **variables)
  end

  private

  def variables
    instance_variables.inject({}) do |hash, var|
      next hash if var.to_s.starts_with?('@_')

      hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
      hash
    end
  end
end
