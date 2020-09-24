class AlaveteliLocalization
  # Handle transformations of a hyphenated Locale identifier (e.g. "en-GB").
  class HyphenatedLocale < Locale
    private

    def split
      to_s.split('-')
    end
  end
end
