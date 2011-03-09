require 'fast_gettext/mo_file'
module FastGettext
  # Responsibility:
  #  - abstract po files for Po Repository
  # TODO refactor...
  class PoFile
    def self.to_mo_file(file, options={})
      require 'fast_gettext/vendor/poparser'
      mo_file = FastGettext::GetText::MOFile.new
      FastGettext::GetText::PoParser.new.parse(File.read(file), mo_file, !options[:ignore_fuzzy], !options[:ignore_obsolete])
      MoFile.new(mo_file)
    end
  end
end
