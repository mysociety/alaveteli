##
# Calculate amount + tax for an attribute
#
# Set STRIPE_TAX_RATE in config/general.yml to change the tax rate.
#
# Example
#   klass = Struct.new(:amount).include(Taxable)
#   klass.tax(:amount)
#   instance = klass.new(833)
#   instance.amount
#   # => 833
#   instance.amount_with_tax
#   # => 1000
#
module Taxable
  extend ActiveSupport::Concern

  included do
    class << self
      def tax(*attributes)
        attributes.each do |attribute|
          define_method("#{attribute}_with_tax") do
            net = send(attribute)
            vat = (net * tax_rate).round(0)
            net + vat
          end
        end
      end
    end
  end

  private

  def tax_rate
    @tax_rate ||= AlaveteliConfiguration.stripe_tax_rate.to_f
  end
end
