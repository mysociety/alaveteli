##
# Legislation representing the law used to make information requests.
#
class Legislation
  UnknownLegislation = Class.new(StandardError)
  UnknownLegislationVariant = Class.new(StandardError)

  def self.all
    [
      new(
        key: 'foi',
        short: _('FOI')
      ),
      new(
        key: 'eir',
        short: _('EIR')
      )
    ]
  end

  def self.find(key)
    all.find { |legislation| legislation.key == key }
  end

  def self.find!(key)
    legislation = find(key)
    return legislation if legislation

    raise UnknownLegislation.new("Unknown legislation #{key}.")
  end

  def self.keys
    all.map(&:key)
  end

  def self.default
    find('foi')
  end

  def self.for_public_body(public_body)
    if public_body.has_tag?('eir_only')
      [find('eir')]
    else
      all
    end
  end

  attr_reader :key, :variants

  def initialize(key:, **variants)
    @key = key
    @variants = variants
  end

  def to_s(variant = :short)
    @variants.fetch(variant)
  rescue KeyError
    raise UnknownLegislationVariant.new(
      "Unknown variant #{variant} in legislation #{key}."
    )
  end
end
