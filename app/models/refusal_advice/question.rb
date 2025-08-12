##
# A single question that we present to users to help them challenge refusals.
#
class RefusalAdvice::Question < RefusalAdvice::Block
  def label
    renderable_object(data[:label])
  end

  def hint
    renderable_object(data[:hint])
  end

  def options
    collection(data[:options])
  end

  def to_partial_path
    'help/refusal_advice/question'
  end
end
