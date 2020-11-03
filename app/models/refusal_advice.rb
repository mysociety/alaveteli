##
# A collection of Questions that help users challenge refusals.
#
class RefusalAdvice
  def self.default
    files = Rails.configuration.paths['config/refusal_advice'].existent
    new(Store.from_yaml(files))
  end

  def initialize(data)
    @data = data
  end

  def legislation
    Legislation.default
  end

  def questions
    data[legislation.key.to_sym][:questions].
      map { |question| Question.new(question) }
  end

  def actions
    data[legislation.key.to_sym][:actions].
      map { |action| Action.new(action) }
  end

  def ==(other)
    data == other.data
  end

  protected

  attr_reader :data
end
