require 'fast_gettext/vendor/mofile'
module FastGettext
  # Responsibility:
  #  - abstract mo files for Mo Repository
  class MoFile
    PLURAL_SEPERATOR = "\000"

    # file => path or FastGettext::GetText::MOFile
    def initialize(file)
      if file.is_a? FastGettext::GetText::MOFile
        @data = file
      else
        @data = FastGettext::GetText::MOFile.open(file, "UTF-8")
      end
      make_singular_and_plural_available
    end

    def [](key)
      @data[key]
    end

    #returns the plural forms or all singular translations that where found
    def plural(*msgids)
      translations = plural_translations(msgids)
      return translations unless translations.empty?
      msgids.map{|msgid| self[msgid] || msgid} #try to translate each id
    end

    def pluralisation_rule
      #gettext uses 0 as default rule, which would turn off all pluralisation, very clever...
      #additionally parsing fails when directly accessing po files, so this line was taken from gettext/mofile
      (@data['']||'').split("\n").each do |line|
        return lambda{|n|eval($2)} if /^Plural-Forms:\s*nplurals\s*\=\s*(\d*);\s*plural\s*\=\s*([^;]*)\n?/ =~ line
      end
      nil
    end

    def self.empty
      MoFile.new(File.join(File.dirname(__FILE__),'vendor','empty.mo'))
    end

    private

    #(if plural==singular, prefer singular)
    def make_singular_and_plural_available
      data = {}
      @data.each do |key,translation|
        next unless key.include? PLURAL_SEPERATOR
        singular, plural = split_plurals(key)
        translation = split_plurals(translation)
        data[singular] ||= translation[0]
        data[plural] ||= translation[1]
      end
      @data.merge!(data){|key,old,new| old}
    end

    def split_plurals(singular_plural)
      singular_plural.split(PLURAL_SEPERATOR)
    end

    # Car, Cars => [Auto,Autos] or []
    def plural_translations(msgids)
      plurals = self[msgids*PLURAL_SEPERATOR]
      if plurals then split_plurals(plurals) else [] end
    end
  end
end
