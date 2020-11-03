##
# A single suggestion that we present to users to help them challenge refusals.
#
class RefusalAdvice::Suggestion < RefusalAdvice::Block
  def action
    data[:action]
  end

  def response_template
    data[:response_template]
  end
end
