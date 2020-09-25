class AlaveteliLocalization
  # Handle transformations of un anderscorred Locale identifier (e.g. "en_GB").
  class UnderscorredLocale < Locale
    def self_and_parents
      super.prepend(canonicalize)
    end

    private

    def split
      to_s.split('_')
    end
  end
end
