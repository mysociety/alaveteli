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
    Array(data.dig(legislation.to_sym, :questions)).
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
  # Retrieve the previously suggested actions from by the refusal advice wizard
  # for a given InfoRequest and user.
  #
  def suggested_actions
    wizard_answer = refusal_advice_wizard_answers_by(@options[:user]).last
    return unless wizard_answer

    action = wizard_answer.params[:id]
    suggestions = wizard_answer.params[:actions][action.to_sym]

    suggestions.inject([]) do |memo, (k, v)|
      memo << "refusal_advice:#{k}" if v
      memo
    end
  end

  ##
  # Return a Array of arrays which can be used with options_for_select to show
  # legislation references options which have refusal advice snippets.
  #
  def filter_options
    tags = snippets.tags
    legislation.refusals.
      inject([]) do |memo, r|
        tag = "refusal_advice:#{r.to_param}"
        memo << [r.to_s, tag] if tags.include?(tag)
        memo
      end
  end

  def ==(other)
    data == other.data
  end

  protected

  attr_reader :data, :info_request

  private

  def refusal_advice_wizard_answers_by(user)
    @info_request.info_request_events.where(
      event_type: 'refusal_advice'
    ).order(created_at: :desc).select do |event|
      # TODO: Add user association to InfoRequestEvent so that we can filter by
      # user during the SQL query to improve performance.
      event.params[:user_id] == user.id
    end
  end
end
