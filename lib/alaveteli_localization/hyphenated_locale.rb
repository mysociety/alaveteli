class AlaveteliLocalization
  # Handle transformations of a hyphenated Locale identifier (e.g. "en-GB").
  class HyphenatedLocale < Locale
    def self_and_parents
      without_canonicalized = super
      index = without_canonicalized.find_index(self) + 1
      without_canonicalized.insert(index, canonicalize)
    end

    private

    def split
      to_s.split('-')
    end
  end
end
