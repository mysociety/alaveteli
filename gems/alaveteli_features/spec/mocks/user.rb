class MockUser # :nodoc:
  attr_reader :id, :roles

  def initialize(id, roles = [])
    @id = id
    @roles = roles
  end

  # Must respond to flipper_id
  alias flipper_id id
end
