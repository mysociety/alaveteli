# Setup questions to ask before the new request is rendered
#
# This can be used to dissuade requests for personal information.
#
# PublicBodyQuestion.build(
#   public_body: home_office,
#   key: :visa,
#   question: 'Asking about your Visa?',
#   response: 'Please contact the Home Office directly.'
# )
#
# PublicBodyQuestion.build(
#   public_body: home_office,
#   key: :foi,
#   question: 'Making an actual FOI request?',
#   response: :allow
# )
#
class PublicBodyQuestion
  def self.build(*args)
    @all ||= []
    @all << new(*args)
  end

  def self.fetch(public_body)
    (@all || []).select { |q| q.public_body == public_body }
  end

  attr_reader :public_body, :key, :response, :text

  def initialize(options = {})
    @public_body = options.fetch(:public_body)
    @key = options.fetch(:key)
    @text = options.fetch(:question)
    @response = options.fetch(:response)
  end

  def action
    response == :allow ? :allow : :deny
  end
end
