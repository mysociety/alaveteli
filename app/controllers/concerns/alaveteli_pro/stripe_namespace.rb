module AlaveteliPro::StripeNamespace
  extend ActiveSupport::Concern

  def add_stripe_namespace(string)
    return string if namespace.blank?
    return string if string.start_with?(/#{namespace}-/)

    [namespace, string].join('-')
  end

  def remove_stripe_namespace(string)
    return string if namespace.blank?
    return string unless string.start_with?(/#{namespace}-/)

    string.sub(/^#{namespace}-/, '')
  end

  private

  def namespace
    AlaveteliConfiguration.stripe_namespace
  end
end
