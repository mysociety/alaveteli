# -*- encoding : utf-8 -*-
class AlaveteliLocalization
  autoload :HyphenatedLocale, 'alaveteli_localization/hyphenated_locale'
  autoload :UnderscorredLocale, 'alaveteli_localization/underscorred_locale'

  # Handle transformations of a Locale identifier.
  class Locale
    include Comparable

    # rubocop:disable Layout/LineLength
    PARSERS = {
      /\A[a-z]{2,3}-[A-Z]{2,3}\z/ => AlaveteliLocalization::HyphenatedLocale,
      /\A[a-z]{2,3}_[A-Z1-9]{2,3}\z/ => AlaveteliLocalization::UnderscorredLocale,
      /\A[a-z]{2,3}\z/ => AlaveteliLocalization::Locale
    }.freeze
    # rubocop:enable Layout/LineLength

    def self.parse(identifier)
      return identifier if identifier.is_a?(Locale)

      identifier = identifier.to_s
      ifnone = -> { raise ArgumentError, 'invalid identifier' }
      _, klass = PARSERS.find(ifnone) { |regexp, _| identifier.match(regexp) }

      klass.new(identifier)
    end

    def initialize(identifier)
      @identifier = identifier
    end

    def language
      split[0]
    end

    # Public: The optional regional dialect.
    #
    # Can't use `#last` otherwise the #language gets returned due to the split
    # String ending up as a single element Array.
    #
    # Returns a String if there is a region.
    # Returns nil if there is no region.
    def region
      split[1]
    end

    def canonicalize
      self.class.parse(split.join('_'))
    end

    def hyphenate
      self.class.parse(split.join('-'))
    end

    def self_and_parents
      I18n::Locale::Tag::Simple.new(hyphenate).
        self_and_parents.
        map { |tag| self.class.parse(tag) }
    end

    def i18n_fallbacks(default = nil)
      default = self.class.parse(default) if default
      (self_and_parents | Array(default&.i18n_fallbacks)).
        compact.map(&:to_sym).uniq
    end

    def to_s
      identifier
    end

    def to_sym
      identifier.to_sym
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    protected

    attr_reader :identifier

    private

    def split
      [to_s]
    end
  end
end
