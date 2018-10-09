class User::WithRequest < SimpleDelegator
  attr_reader :request

  delegate :user_agent, to: :request

  def initialize(user, request)
    @request = request
    super(user)
  end
end
