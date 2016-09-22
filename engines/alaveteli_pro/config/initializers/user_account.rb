AlaveteliPro::Engine.config.to_prepare do
  if AlaveteliPro.user_class && !AlaveteliPro.user_class.constantize.included_modules.include?(AlaveteliPro::UserAccount)
    ActiveSupport::Deprecation.warn "#{AlaveteliPro.user_class} must include AlaveteliPro::UserAccount"
    AlaveteliPro.user_class.constantize.class_eval do
      include AlaveteliPro::UserAccount
    end
  end
end