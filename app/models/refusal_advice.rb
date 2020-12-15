##
# A collection of Questions that help users challenge refusals.
#
class RefusalAdvice
  def self.default(info_request = nil)
    files = Rails.configuration.paths['config/refusal_advice'].existent
    new(Store.from_yaml(files), info_request: info_request)
  end

  def initialize(data, info_request: nil)
    @data = data
    @info_request = info_request
  end

  def legislation
    info_request&.legislation || Legislation.default
  end

  def questions
    data[legislation.to_sym][:questions].
      map { |question| Question.new(question) }
  end

  def actions
    data[legislation.to_sym][:actions].
      map { |action| Action.new(action) }
  end

  def ==(other)
    data == other.data
  end

  protected

  attr_reader :data, :info_request
end
