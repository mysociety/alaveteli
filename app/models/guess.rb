require 'text'

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

  def id_score
    return 1 unless self[:id]
    similarity(self[:id], info_request.id)
  end

  def idhash_score
    return 1 unless self[:idhash]
    similarity(self[:idhash], info_request.idhash)
  end

  def ==(other)
    info_request == other.info_request && components == other.components
  end

  def match_method
    components.keys.first
  end

  private

  def similarity(a, b)
    Text::WhiteSimilarity.similarity(a.to_s, b.to_s)
  end
end
