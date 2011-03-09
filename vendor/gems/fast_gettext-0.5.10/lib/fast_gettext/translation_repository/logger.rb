require 'fast_gettext/translation_repository/base'

module FastGettext
  module TranslationRepository
    # This should be used in a TranslationRepository::Chain, so tat untranslated keys can be found
    # Responsibility:
    #  - log every translation call
    class Logger < Base
      attr_accessor :callback

      def initialize(name,options={})
        super
        self.callback = options[:callback]
      end

      def [](key)
        callback.call(key)
        nil
      end

      def plural(*keys)
        callback.call(keys)
        []
      end
    end
  end
end