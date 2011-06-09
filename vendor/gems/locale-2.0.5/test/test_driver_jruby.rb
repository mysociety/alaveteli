
begin
  require 'locale/driver/jruby'
  require 'test/unit'
  class TestDiverJRuby < Test::Unit::TestCase

    def setup
      ENV["LC_ALL"] = nil
      ENV["LC_MESSAGES"] = nil
      ENV["LANG"] = nil
      ENV["LANGUAGE"] = nil
    end

    def set_locale(tag)
      java.util.Locale.setDefault(java.util.Locale.new(tag.language, tag.region, tag.variants.to_s))
    end

    def test_charset
      # Depends on system value when jvm is started.
    end

    def test_locales
      tag = Locale::Tag::Common.parse("ja-JP")
      set_locale(tag)
      assert_equal [tag], Locale::Driver::JRuby.locales
    end

    def test_locales_with_env
      ENV["LC_ALL"] = "ja_JP.EUC-JP"
      assert_equal Locale::Tag::Posix.parse("ja_JP.EUC-JP"), Locale::Driver::JRuby.locales[0]
      assert_equal "EUC-JP", Locale::Driver::JRuby.charset

      ENV["LC_ALL"] = "ja_JP"
      assert_equal Locale::Tag::Posix.parse("ja_JP"), Locale::Driver::JRuby.locales[0]
  
      ENV["LC_ALL"] = "C"
      assert_equal Locale::Tag::Posix.parse("C"), Locale::Driver::JRuby.locales[0]
    end
  end

rescue LoadError
  puts "jruby test was skipped."
end
