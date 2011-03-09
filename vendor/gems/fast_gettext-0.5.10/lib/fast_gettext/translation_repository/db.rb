require 'active_record'
module FastGettext
  module TranslationRepository
    # Responsibility:
    #  - provide access to translations in database through a database abstraction
    #
    #  Options:
    #   :model => Model that represents your keys
    #   you can either use the models supplied under db/, extend them or build your own
    #   only constraints:
    #     key: find_by_key, translations
    #     translation: text, locale
    class Db
      def initialize(name,options={})
        @model = options[:model]
      end

      @@seperator = '||||' # string that seperates multiple plurals
      def self.seperator=(sep);@@seperator = sep;end
      def self.seperator;@@seperator;end

      def available_locales
        if @model.respond_to? :available_locales
          @model.available_locales || []
        else
          []
        end
      end

      def pluralisation_rule
        if @model.respond_to? :pluralsation_rule
          @model.pluralsation_rule
        else
          nil
        end
      end

      def [](key)
        @model.translation(key, FastGettext.locale)
      end

      def plural(*args)
        if translation = @model.translation(args*self.class.seperator, FastGettext.locale)
          translation.to_s.split(self.class.seperator)
        else
          []
        end
      end

      def self.require_models
        folder = "fast_gettext/translation_repository/db_models"
        require "#{folder}/translation_key"
        require "#{folder}/translation_text"
        Module.new do
          def self.included(base)
            puts "you no longer need to include the result of require_models"
          end
        end
      end
    end
  end
end