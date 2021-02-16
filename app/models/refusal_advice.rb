##
# A collection of Questions that help users challenge refusals.
#
class RefusalAdvice
  UnknownAction = Class.new(StandardError)

  def self.default(info_request = nil, **options)
    files = Rails.configuration.paths['config/refusal_advice'].existent
    new(Store.from_yaml(files), info_request: info_request, **options)
  end

  def initialize(data, info_request: nil, **options)
    @data = data
    @info_request = info_request
    @options = options
  end

  def legislation
    info_request&.legislation || Legislation.default
  end

  def questions
    Array(data[legislation.to_sym][:questions]).
      map { |question| Question.new(question) }
  end

  def actions
    data[legislation.to_sym][:actions].
      map { |action| Action.new(action) }
  end

  ##
  # Return any OutgoingMessage refusal advice snippets. Also can pass in an
  # additional scope to further limit the snippets returned. EG if we want
  # internal_review advice or not.
  #
  def snippets
    scope = OutgoingMessage::Snippet.with_tag('refusal_advice')
    return scope.with_tag('internal_review') if @options[:internal_review]
    scope.without_tag('internal_review')
  end

  ##
  # Return a Array of arrays which can be used with options_for_select to show
  # legislation references options which have refusal advice snippets.
  #
  def filter_options
    tags = snippets.tags
    legislation.refusals.
      inject([]) do |memo, r|
        tag = "refusal:#{r.to_param}"
        memo << [r.to_s, tag] if tags.include?(tag)
        memo
      end
  end

  def ==(other)
    data == other.data
  end

  protected

  attr_reader :data, :info_request
end
