##
# An action which contains many different suggestions that we present to users
# to # help them challenge refusals
#
class RefusalAdvice::Action < RefusalAdvice::Block
  RedirectionError = Class.new(StandardError)

  def title
    data[:title]
  end

  def header
    data[:header] || title
  end

  def body
    renderable_object(data[:body])
  end

  def button
    data[:button] || title
  end

  def suggestions
    Array(data[:suggestions]).
      map { |suggestion| RefusalAdvice::Suggestion.new(suggestion) }
  end

  def target
    data[:target] || {}
  end

  def to_partial_path
    'help/refusal_advice/action'
  end
end
