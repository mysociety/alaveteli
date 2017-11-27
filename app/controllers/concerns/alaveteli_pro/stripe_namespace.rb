module AlaveteliPro::StripeNamespace
  extend ActiveSupport::Concern

  def add_stripe_namespace(string)
    namespace.blank? ? string : [namespace, string].join('-')
  end

  def remove_stripe_namespace(string)
    namespace.blank? ? string : string.sub(/^#{namespace}-/, '')
  end

  private

  def namespace
    AlaveteliConfiguration.stripe_namespace
  end
end
