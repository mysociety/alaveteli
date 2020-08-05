# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliLocalization do

  describe '.set_locales' do

    before do
      AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
    end

    context 'when dealing with FastGettext' do

      it 'sets FastGettext.locale' do
        expect(FastGettext.locale).to eq("en_GB")
      end

      it 'sets FastGettext.locale correctly if given a hypheanted locale' do
        AlaveteliLocalization.set_locales('en-GB es', 'en-GB')
        expect(FastGettext.locale).to eq('en_GB')
      end

      it 'sets FastGettext.default_locale' do
        expect(FastGettext.default_locale).to eq("en_GB")
      end

      it 'sets FastGettext.default_available_locales' do
        expect(FastGettext.default_available_locales).to eq([:en_GB, :es])
      end

    end

    context 'when dealing with I18n' do

      context 'when enforce_available_locales is true' do

        around do |example|
          enforce_available_locales = I18n.config.enforce_available_locales
          I18n.config.enforce_available_locales = true
          example.run
          I18n.config.enforce_available_locales = enforce_available_locales
        end

        it 'allows a new locale to be set as the default' do
          AlaveteliLocalization.set_locales('nl en', 'nl')
          expect(I18n.default_locale).to eq(:nl)
        end

      end

      it 'sets I18n.locale' do
        expect(I18n.locale).to eq(:"en-GB")
      end

      it 'sets I18n.default_locale' do
        expect(I18n.default_locale).to eq(:"en-GB")
      end

      it 'sets I18n.available_locales' do
        expect(I18n.available_locales).to eq([:"en-GB", :en, :es])
      end

    end

    context 'when translating' do

      it 'can correct translate 2 letter language locale' do
        AlaveteliLocalization.set_locales('cy', 'cy')
        expect(I18n.translate('date.abbr_month_names')).to include(
          'Ion', 'Chw', 'Maw', 'Ebr', 'Mai', 'Meh', 'Gor', 'Awst', 'Med', 'Hyd',
          'Tach', 'Rha'
        )
      end

      it 'can correct translate underscore language locale' do
        AlaveteliLocalization.set_locales('is_IS', 'is_IS')
        expect(I18n.translate('date.abbr_month_names')).to include(
          'jan', 'feb', 'mar', 'apr', 'maí', 'jún', 'júl', 'ágú', 'sep', 'okt',
          'nóv', 'des'
        )
      end

      it 'can correct translate hyphenated language locale' do
        AlaveteliLocalization.set_locales('fr-BE', 'fr-BE')
        expect(I18n.translate('date.abbr_month_names')).to include(
          'jan.', 'fév.', 'mar.', 'avr.', 'mai', 'juin', 'juil.', 'août',
          'sept.', 'oct.', 'nov.', 'déc.'
        )
      end

    end

    it 'sets the locales for the custom routing filter' do
      expect(RoutingFilter::Conditionallyprependlocale.locales).
        to eq([:en_GB, :es])
    end

    it 'handles being passed a symbol as available_locales' do
      AlaveteliLocalization.set_locales(:es, :es)
      expect(AlaveteliLocalization.available_locales).to eq(['es'])
    end

    it 'handles being passed hyphenated strings as available_locales' do
      AlaveteliLocalization.set_locales('en-GB nl-BE es', :es)
      expect(AlaveteliLocalization.available_locales).
        to eq(['en_GB', 'nl_BE', 'es'])
    end

  end

  describe '.set_session_locale' do

    it 'sets the current locale' do
      AlaveteliLocalization.set_session_locale('es')
      expect(AlaveteliLocalization.locale).to eq('es')
    end

    it 'does not affect the default locale' do
      AlaveteliLocalization.set_session_locale('es')
      expect(AlaveteliLocalization.default_locale).to eq('en')
    end

    it 'uses the first non blank argument' do
      expect(AlaveteliLocalization.set_session_locale(nil, 'es', 'en')).
        to eq('es')

      expect(AlaveteliLocalization.set_session_locale('', 'es', 'en')).
        to eq('es')
    end

    it 'uses the current default if the supplied value is not in available_locales' do
      expect(AlaveteliLocalization.set_session_locale('pt')).to eq('en')
    end

    it 'uses the current default if only blank arguments are supplied' do
      expect(AlaveteliLocalization.set_session_locale('', nil)).to eq('en')
    end

    it 'accepts a symbol or a string' do
      expect(AlaveteliLocalization.set_session_locale(:es)).to eq('es')
    end

  end

  describe '.with_locale' do

    it 'yields control to i18n' do
      expect { |b| AlaveteliLocalization.with_locale(:es, &b) }.
        to yield_control
    end

    it 'returns the same result as if we had called I18n.with_locale directly' do
      result = AlaveteliLocalization.with_locale(:es) do
        AlaveteliLocalization.locale
      end
      expect(result).to eq("es")
    end

  end

  describe '.locale' do

    it 'returns the current locale' do
      expect(AlaveteliLocalization.locale).to eq('en')
    end

    it 'returns the locale in the underscore format' do
      AlaveteliLocalization.set_locales('en_GB', 'en_GB')
      expect(AlaveteliLocalization.locale).to eq('en_GB')
    end

  end

  describe '.default_locale' do

    it 'returns the current locale' do
      expect(AlaveteliLocalization.default_locale).to eq('en')
    end

    it 'returns the locale in the underscore format' do
      AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
      expect(AlaveteliLocalization.default_locale).to eq('en_GB')
    end

  end

  describe '.default_locale?' do

    it 'returns true if the supplied locale is the default' do
      expect(AlaveteliLocalization.default_locale?('en')).to eq(true)
    end

    it 'returns false if the supplied locale is not the default' do
      expect(AlaveteliLocalization.default_locale?('es')).to eq(false)
    end

    it 'accepts symbol formatted locales' do
      expect(AlaveteliLocalization.default_locale?(:en)).to eq(true)
    end

    it 'returns false if the supplied locale is nil' do
      expect(AlaveteliLocalization.default_locale?(nil)).to eq(false)
    end

  end

  describe '.available_locales' do

    it 'returns an array of available locales' do
      AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
      expect(AlaveteliLocalization.available_locales).to eq(['en_GB', 'es'])
    end

  end

  describe '.html_lang' do

    it 'returns the current locale' do
      expect(AlaveteliLocalization.html_lang).to eq('en')
    end

    it 'returns the hyphenated format' do
      AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
      expect(AlaveteliLocalization.html_lang).to eq('en-GB')
    end

  end

end
