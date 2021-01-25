##
# Legislation representing the law used to make information requests.
#
class Legislation
  UnknownLegislation = Class.new(StandardError)
  UnknownLegislationVariant = Class.new(StandardError)

  def self.all
    @all ||= [
      new(
        key: 'foi',
        short: _('FOI'),
        full: _('Freedom of Information'),
        with_a: _('A Freedom of Information request'),
        act: _('Freedom of Information Act')
      ),
      new(
        key: 'eir',
        short: _('EIR'),
        full: _('Environmental Information Regulations'),
        with_a: _('An Environmental Information request'),
        act: _('Environmental Information Regulations')
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
    @refusals = variants.fetch(:refusals, [])
    @variants = variants
  end

  def to_sym
    key.to_sym
  end

  def to_s(variant = :short)
    @variants.fetch(variant)
  rescue KeyError
    raise UnknownLegislationVariant.new(
      "Unknown variant #{variant} in legislation #{key}."
    )
  end

  def ==(other)
    other&.to_sym == to_sym
  end

  def find_references(text)
    Legislation::ReferenceCollection.new(legislation: self).match(text)
  end

  def refusals
    @refusals.map do |reference|
      Legislation::Reference.new(legislation: self, reference: reference)
    end
  end
end
