module I18n
  module_function

  def locale=(new_locale)
    FastGettext.locale = new_locale
  end

  def locale
    FastGettext.locale.to_sym
  end

  # since Rails 2.3.8 a config object is used instead of just .locale
  if defined? Config
    class Config
      def locale
        FastGettext.locale.to_sym
      end

       def locale=(new_locale)
        FastGettext.locale=(new_locale)
      end
    end
  end

  # backport I18n.with_locale if it does not exist
  unless respond_to?(:with_locale)
    # Executes block with given I18n.locale set.
    def with_locale(tmp_locale = nil)
      if tmp_locale
        current_locale = self.locale
        self.locale = tmp_locale
      end
      yield
    ensure
      self.locale = current_locale if tmp_locale
    end
  end
end