module AlaveteliPro::StripeNamespace
  extend ActiveSupport::Concern

  def add_stripe_namespace(string, prefix: nil)
    return string if namespace.blank?
    return string if prefix && string.start_with?(/#{prefix}_/)
    return string if string.start_with?(/#{namespace}-/)

    [namespace, string].join('-')
  end

  def remove_stripe_namespace(string, prefix: nil)
    return string if namespace.blank?
    return string if prefix && string.start_with?(/#{prefix}_/)
    return string unless string.start_with?(/#{namespace}-/)

    string.sub(/^#{namespace}-/, '')
  end

  private

  def namespace
    AlaveteliConfiguration.stripe_namespace
  end
end
