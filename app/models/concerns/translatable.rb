module Translatable
  extend ActiveSupport::Concern

  included do
    accepts_nested_attributes_for :translations, reject_if: :empty_translation_in_params?
  end

  def find_translation_by_locale(locale)
    translations.find_by_locale(locale)
  end

  def translated_versions
    translations
  end

  def ordered_translations
    translations.
      select { |translation| AlaveteliLocalization.available_locales.include?(translation.locale.to_s) }.
      sort_by { |translation| AlaveteliLocalization.available_locales.index(translation.locale.to_s) }
  end

  def build_all_translations
    AlaveteliLocalization.available_locales.each do |locale|
      if translations.none? { |translation| translation.locale.to_s == locale }
        translations.build(locale: locale)
      end
    end
  end

  private

  def empty_translation_in_params?(attributes)
    attributes.select { |k, v| v.present? && k.to_s != 'locale' }.empty?
  end
end
