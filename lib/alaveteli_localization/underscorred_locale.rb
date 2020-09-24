class AlaveteliLocalization
  # Handle transformations of un anderscorred Locale identifier (e.g. "en_GB").
  class UnderscorredLocale < Locale
    private

    def split
      to_s.split('_')
    end
  end
end
