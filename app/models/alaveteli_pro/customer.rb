##
# A wrapper for a Stripe::Customer
#
class AlaveteliPro::Customer < SimpleDelegator
  def self.retrieve(id)
    new(Stripe::Customer.retrieve(id))
  end

  def default_source
    @default_source ||= sources.find { |c| c.id == __getobj__.default_source }
  end
end
