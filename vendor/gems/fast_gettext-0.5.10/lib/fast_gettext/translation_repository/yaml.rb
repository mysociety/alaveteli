require 'fast_gettext/translation_repository/base'
require 'yaml'

module FastGettext
  module TranslationRepository
    # Responsibility:
    #  - find and store yaml files
    #  - provide access to translations in yaml files
    class Yaml < Base
      def initialize(name,options={})
        find_and_store_files(options)
        super
      end

      def available_locales
        @files.keys
      end

      def plural(*keys)
        ['one', 'other', 'plural2', 'plural3'].map do |name|
          self[yaml_dot_notation(keys.first, name)]
        end
      end

      def pluralisation_rule
        self['pluralisation_rule'] ? lambda{|n| eval(self['pluralisation_rule']) } : nil
      end

      protected

      MAX_FIND_DEPTH = 10

      def find_and_store_files(options)
        @files = {}
        path = options[:path] || 'config/locales'
        Dir["#{path}/??.yml"].each do |yaml_file|
          locale = yaml_file.match(/([a-z]{2})\.yml$/)[1]
          @files[locale] = load_yaml(yaml_file, locale)
        end
      end

      def current_translations
        @files[FastGettext.locale] || super
      end

      # Given a yaml file return a hash of key -> translation
      def load_yaml(file, locale)
        yaml = YAML.load_file(file)
        yaml_hash_to_dot_notation(yaml[locale])
      end

      def yaml_hash_to_dot_notation(yaml_hash)
        add_yaml_key({}, nil, yaml_hash)
      end

      def add_yaml_key(result, prefix, hash)
        hash.each_pair do |key, value|
          if value.kind_of?(Hash)
            add_yaml_key(result, yaml_dot_notation(prefix, key), value)
          else
            result[yaml_dot_notation(prefix, key)] = value
          end
        end
        result
      end

      def yaml_dot_notation(a,b)
        a ? "#{a}.#{b}" : b
      end
    end
  end
end