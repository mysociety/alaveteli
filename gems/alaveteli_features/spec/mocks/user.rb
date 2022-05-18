class MockUser # :nodoc:
  attr_reader :id

  def initialize(id)
    @id = id
  end

  # Must respond to flipper_id
  alias flipper_id id
end
