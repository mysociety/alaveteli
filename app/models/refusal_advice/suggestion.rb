##
# A single suggestion that we present to users to help them challenge refusals.
#
class RefusalAdvice::Suggestion < RefusalAdvice::Block
  def to_partial_path
    'help/refusal_advice/suggestion'
  end
end
