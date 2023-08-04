##
# A guess at which info request a incoming message should be associated to
#
class Guess
  attr_reader :info_request, :components

  def initialize(info_request, **components)
    @info_request = info_request
    @components = components
  end

  def [](key)
    components[key]
  end

  def ==(other)
    info_request == other.info_request && components == other.components
  end

  def match_method
    components.keys.first
  end
end
