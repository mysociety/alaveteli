# CensorRules can be configured to match/ignore diacritic characters (accents,
# etc)
module CensorRule::Diacritics
  extend ActiveSupport::Concern

  included do
    validate :regexp_ignore_diacritics,
             if: -> { regexp? && ignore_diacritics? }
  end

  private

  def diacritic_expander
    DiacriticExpander.new(case_sensitive: case_sensitive?)
  end

  def regexp_ignore_diacritics
    msg = 'Cannot use regexp and ignore diacritics option together'
    errors.add(:text, msg)
  end
end
