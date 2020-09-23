class AlaveteliLocalization
  # A few helpers for cleaner specs
  module SpecHelpers
    def hyphenated_locale(identifier)
      AlaveteliLocalization::HyphenatedLocale.new(identifier)
    end

    def underscorred_locale(identifier)
      AlaveteliLocalization::UnderscorredLocale.new(identifier)
    end
  end
end
