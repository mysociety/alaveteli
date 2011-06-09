require 'locale'
require 'test/unit'

class TestDetectGeneral < Test::Unit::TestCase

  def setup
    Locale.clear_all
    ENV["LC_ALL"] = nil
    ENV["LC_MESSAGES"] = nil
    ENV["LANG"] = nil
    ENV["LANGUAGE"] = nil
  end

  def test_lc_all
    ENV["LC_ALL"] = "ja_JP.eucJP"
    ENV["LC_MESSAGES"] = "zh_CN.UTF-8"  #Ignored.
    ENV["LANG"] = "ko_KR.UTF-8"  #Ignored.
    ENV["LANGUAGE"] = nil

    lang = Locale.current[0]
    assert_equal Locale::Tag::Posix, lang.class
    assert_equal "ja", lang.language
    assert_equal "JP", lang.region
    assert_equal "eucJP", lang.charset
    assert_equal Locale::Tag::Posix.new("ja", "JP", "eucJP"), lang

    assert_equal "eucJP", Locale.charset
  end

  def test_lc_messages
    ENV["LC_ALL"] = nil
    ENV["LC_MESSAGES"] = "ja_JP.eucJP"
    ENV["LANG"] = "ko_KR.UTF-8"  #Ignored.
    ENV["LANGUAGE"] = nil

    lang = Locale.current[0]
    assert_equal Locale::Tag::Posix, lang.class
    assert_equal "ja", lang.language
    assert_equal "JP", lang.region
    assert_equal "eucJP", lang.charset
    assert_equal Locale::Tag::Posix.new("ja", "JP", "eucJP"), lang

    assert_equal "eucJP", Locale.charset
  end

  def test_lang
    ENV["LC_ALL"] = nil
    ENV["LC_MESSAGES"] = nil
    ENV["LANG"] = "ja_JP.eucJP"
    ENV["LANGUAGE"] = nil

    lang = Locale.current[0]
    assert_equal Locale::Tag::Posix, lang.class
    assert_equal "ja", lang.language
    assert_equal "JP", lang.region
    assert_equal "eucJP", lang.charset
    assert_equal Locale::Tag::Posix.new("ja", "JP", "eucJP"), lang

    assert_equal "eucJP", Locale.charset
  end

  def test_lang_complex
    ENV["LC_ALL"] = "zh_CN.UTF-8"  # Ignored.
    ENV["LC_MESSAGES"] = "ko_KR.UTF-8" #Ingored.
    ENV["LANG"] = "en_US.UTF-8"  # Ignored.
    ENV["LANGUAGE"] ="ja_JP.eucJP:zh_CN.UTF-8"

    lang = Locale.current[0]
    assert_equal Locale::Tag::Posix, lang.class
    assert_equal "ja", lang.language
    assert_equal "JP", lang.region
    assert_equal "eucJP", lang.charset
    assert_equal Locale::Tag::Posix.new("ja", "JP", "eucJP"), lang

    # Use the LANG value (locale charmap don't use LANGUAGE) 
    assert_equal "UTF-8", Locale.charset
  end

  def test_language
    ENV["LC_ALL"] = "ja_JP.Shift_JIS"
    ENV["LANGUAGE"] = "zh_CN.UTF-8:ja_JP"

    tags = Locale.current
    assert_equal Locale::Tag::Posix, tags[0].class
    assert_equal Locale::Tag::Posix, tags[1].class

    assert_equal "zh", tags.language
    assert_equal "CN", tags.region
    assert_equal "UTF-8", tags.charset

    assert_equal "zh", tags[0].language
    assert_equal "CN", tags[0].region
    assert_equal "UTF-8", tags[0].charset

    assert_equal "ja", tags[1].language
    assert_equal "JP", tags[1].region
    assert_equal nil, tags[1].charset

    assert_equal Locale::TagList.new([Locale::Tag::Posix.new("zh", "CN", "UTF-8"), 
	           Locale::Tag::Posix.new("ja", "JP")]), tags

    assert_equal "Shift_JIS", Locale.charset
  end

  def test_no_charset
    ENV["LC_ALL"] = "cs_CZ"

    lang = Locale.current[0]
    assert_equal Locale::Tag::Posix, lang.class

    assert_equal "cs", lang.language
    assert_equal "CZ", lang.region
    assert_equal nil, lang.charset
    assert_equal Locale::Tag::Posix.new("cs", "CZ"), lang

=begin
 This test doesn't work any environment such as Ubuntu.
 Because this method gets the system locale via "locale -a" command.
    if /linux|bsd/ =~ RUBY_PLATFORM
      assert_equal "ISO-8859-2", Locale.charset   
    end
=end
  end

  def test_default
    return unless /linux|bsd/ =~ RUBY_PLATFORM
    Locale.set_default("yo_NG")
    assert_equal Locale::Tag.parse("yo_NG"), Locale.default
    assert_equal Locale::Tag.parse("yo_NG"), Locale.current[0]
    Locale.set_default(nil)

    Locale.default = "fr"
    assert_equal Locale::Tag.parse("fr"), Locale.default
    assert_equal Locale::Tag.parse("fr"), Locale.current[0]
    Locale.default = nil
  end

  def test_current
    Locale.set_current("yo_NG")
    assert_equal Locale::Tag.parse("yo_NG"), Locale.current[0]

    Locale.current = "fr"
    assert_equal Locale::Tag.parse("fr"), Locale.current[0]

    Locale.set_default("yo_NG")
    Locale.current = "fr"
    assert_equal Locale::Tag.parse("yo_NG"), Locale.default
    assert_equal Locale::Tag.parse("fr"), Locale.current[0]
    Locale.set_default(nil)
  end

  def test_clear
    ENV["LC_ALL"] = "ja_JP.Shift_JIS"
    ENV["LANGUAGE"] = nil

    assert_equal Locale::Tag.parse("ja_JP.Shift_JIS"), Locale.current[0]
    Locale.clear
    ENV["LANGUAGE"] = "zh_CN.UTF-8:ja_JP"
    assert_equal Locale::Tag::Posix.parse("zh_CN.UTF-8"), Locale.current[0]
    assert_equal Locale::Tag::Posix.parse("ja_JP"), Locale.current[1]
    
  end

end
