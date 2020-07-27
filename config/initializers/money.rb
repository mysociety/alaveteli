# Disable i18n which requires config/locales/*.yml files. Instead this allows
# the Money gem to format currencies
Money.locale_backend = :currency

# Use the new default round mode to get rid of deprecation warnings - this can
# be remove when upgrading the next major release of the Money gem
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
