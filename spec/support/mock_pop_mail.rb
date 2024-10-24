class MockPopMail
  def initialize(rfc2822, number)
    @rfc2822 = rfc2822
    @number = number
    @deleted = false
  end

  def pop
    @rfc2822
  end

  attr_reader :number

  def to_s
    "#{number}: #{pop}"
  end

  def delete
    @deleted = true
  end

  def deleted?
    @deleted
  end

  def unique_id
    @number.to_s
  end
end
