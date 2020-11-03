##
# An action which contains many different suggestions that we present to users
# to # help them challenge refusals
#
class RefusalAdvice::Action < RefusalAdvice::Block
  def title
    data[:title]
  end

  def header
    data[:header]
  end

  def button
    data[:button]
  end

  def suggestions
    data[:suggestions]&.
      map { |suggestion| RefusalAdvice::Suggestion.new(suggestion) }
  end
end
