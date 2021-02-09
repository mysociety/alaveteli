##
# A single suggestion that we present to users to help them challenge refusals.
#
class RefusalAdvice::Suggestion < RefusalAdvice::Block
  def action
    data[:action]
  end

  def advice
    renderable_object(data[:advice])
  end

  def response_template
    data[:response_template]
  end

  def to_partial_path
    'help/refusal_advice/suggestion'
  end
end
