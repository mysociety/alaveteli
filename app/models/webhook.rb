class Webhook
  attr_reader :payload, :signature

  ParserError = Class.new(StandardError)
  MissingTypeError = Class.new(NoMethodError)
  VerificationError = Class.new(StandardError)

  def initialize(payload:, signature:)
    @payload = payload
    @signature = signature
  end

  def event
    begin
      @event ||= Stripe::Webhook.construct_event(
        payload, signature, secret
      )

    rescue JSON::ParserError => ex
      raise ParserError.new(ex)

    rescue Stripe::SignatureVerificationError => ex
      raise VerificationError.new(ex)
    end
  end

  def type
    type = event.type if event.respond_to?(:type)
    type || raise(MissingTypeError,
                  "undefined method `type' for #{event.inspect}")
  end

  def plans
    @plans ||= (
      plans = []

      case event.data.object.object
      when 'subscription'
        plans = get_plan_ids(event.data.object.items)
      when 'invoice'
        plans = get_plan_ids(event.data.object.lines)
      end

      # ignore any plans that don't start with our namespace
      plans.select { |plan| plan_matches_namespace(plan) }
    )
  end

  private

  def secret
    AlaveteliConfiguration.stripe_webhook_secret
  end

  def plan_matches_namespace(plan_id)
    (AlaveteliConfiguration.stripe_namespace == '' ||
     plan_id =~ /^#{AlaveteliConfiguration.stripe_namespace}/)
  end

  def get_plan_ids(items)
    items.map { |item| item.plan.id if item.plan }.compact.uniq
  end
end
