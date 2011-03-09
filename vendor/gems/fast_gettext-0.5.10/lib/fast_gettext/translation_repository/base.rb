module FastGettext
  module TranslationRepository
    # Responsibility:
    #  - base for all repositories
    #  - fallback as empty repository, that cannot translate anything but does not crash
    class Base
      def initialize(name,options={})
        @name = name
        @options = options
      end

      def pluralisation_rule
        nil
      end

      def available_locales
        []
      end

      def [](key)
        current_translations[key]
      end

      def plural(*keys)
        current_translations.plural(*keys)
      end

      protected

      def current_translations
        MoFile.empty
      end

      def find_files_in_locale_folders(relative_file_path,path)
        path ||= "locale"
        raise "path #{path} cound not be found!" unless File.exist?(path)

        @files = {}
        Dir[File.join(path,'*')].each do |locale_folder|
          next unless File.basename(locale_folder) =~ LOCALE_REX
          file = File.join(locale_folder,relative_file_path)
          next unless File.exist? file
          locale = File.basename(locale_folder)
          @files[locale] = yield(locale,file)
        end
      end
    end
  end
end