module GettextI18nRails
  mattr_accessor :translations_are_html_safe

  module HtmlSafeTranslations
    # also make available on class methods
    def self.included(base)
      base.extend self
    end

    def _(*args)
      html_safe_if_wanted super
    end

    def n_(*args)
      html_safe_if_wanted super
    end

    def s_(*args)
      html_safe_if_wanted super
    end

    private

    def html_safe_if_wanted(text)
      return text unless GettextI18nRails.translations_are_html_safe
      text.to_s.html_safe
    end
  end
end