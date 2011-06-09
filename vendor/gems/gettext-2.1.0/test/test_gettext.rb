# -*- coding: utf-8 -*-
require 'testlib/helper.rb'

require 'testlib/simple.rb'
require 'testlib/gettext.rb'
require 'testlib/sgettext.rb'
require 'testlib/nsgettext.rb'
require 'testlib/pgettext.rb'
require 'testlib/npgettext.rb'

class TestGetText < Test::Unit::TestCase

  def setup
    ENV["LC_ALL"] = "ja_JP.UTF-8"
    ENV["LANG"] = "ja_JP.UTF-8"
    GetText.locale = nil
    GetText::TextDomainManager.clear_caches
  end

  def test_change_locale
    GetText.locale = nil
    bindtextdomain("test2", "locale")
    test = Simple.new
    assert_equal("japanese", test.test)
    set_locale("fr")
    assert_equal("french", test.test) # influence of previous line
    assert_equal("FRENCH:ONE IS 1.", test.test_formatted_string)
    set_locale("ja")
    assert_equal("JAPANESE", _("LANGUAGE")) # influence of previous line
    assert_equal("japanese", test.test)
 end

  def test_no_msgstr
    bindtextdomain("test1", :path => "locale")
    assert_equal("nomsgstr", _("nomsgstr"))
  end

  def test_empty
    bindtextdomain("test1", "locale")
    assert_equal("japanese", gettext("language"))
    assert_equal("", gettext(""))
    assert_equal("", gettext(nil))
  end

  def test_gettext
    test = TestRubyParser.new
    assert_equal("AAA", test.test_1)
    assert_equal("AAA\n", test.test_2)
    assert_equal("BBB\nCCC", test.test_3)
    assert_equal("BBB
CCC
DDD
", test.test_4)
    assert_equal("EEE", test.test_5)
    assert_equal("EEEfooFFF", test.test_6)
    assert_equal("GGGHHHIII", test.test_7)
  end

  def test_N_
    assert_equal("test", N_("test"))
  end

  def test_sgettext
    test = TestSGetText.new

    assert_equal("MATCHED", test.test_1)
    assert_equal("MATCHED", test.test_2)
    assert_equal("AAA", test.test_3)
    assert_equal("CCC", test.test_4)
    assert_equal("CCC", test.test_5)
    assert_equal("BBB", test.test_6)
    assert_equal("B|BB", test.test_7)
    assert_equal("MATCHED", test.test_8)
    assert_equal("BBB", test.test_9)
  end

  def test_s_uses_no_seperator_when_nil_is_given
    assert_equal "AAA|BBB", s_("AAA|BBB", nil)
  end

  def test_pgettext
    GetText.locale = nil
    test = TestPGetText.new

    assert_equal("えーびー", test.test_1)
    assert_equal("えーびー", test.test_2)
    assert_equal("えーびーしー", test.test_3)
    assert_equal("CCC", test.test_4)
    assert_equal("しーびー", test.test_5)
    assert_equal("びー", test.test_6)

    GetText.locale = "en"
    test = TestPGetText.new

    assert_equal("BBB", test.test_1)
    assert_equal("BBB", test.test_2)
    assert_equal("CCC", test.test_3)
    assert_equal("CCC", test.test_4)
    assert_equal("BBB", test.test_5)
    assert_equal("BBB", test.test_6)
  end

  def test_npgettext
    GetText.locale = nil
    test = TestNPGetText.new
    assert_equal(["一つの本", "%{num}の本たち"], test.test_1)
    assert_equal(["一つの本", "%{num}の本たち"], test.test_2)
    assert_equal(["一つのハードカバー本", "%{num}のハードカバー本たち"], test.test_3)
    assert_equal(["マガジンを1冊持ってます。", "マガジンたちを%{num}冊持ってます。"], test.test_4)
    assert_equal(["a picture", "%{num} pictures"], test.test_5)
  end

  def test_n_defaults_to_1_when_number_is_missing
    assert_equal n_("aaa","aaa2",1), "aaa"
  end

  def test_nsgettext
    GetText.locale = nil
    test = TestNSGetText.new
    assert_equal(["single", "plural"], test.test_1)
    assert_equal(["single", "plural"], test.test_2)
    assert_equal(["AAA", "BBB"], test.test_3)
    assert_equal(["CCC", "DDD"], test.test_4)
    assert_equal(["CCC", "DDD"], test.test_5)
    assert_equal(["BBB", "CCC"], test.test_6)
    assert_equal(["B|BB", "CCC"], test.test_7)
    assert_equal(["single", "plural"], test.test_8)
    assert_equal(["BBB", "DDD"], test.test_9)
  end

  def test_plural
    GetText.locale = nil
    bindtextdomain("plural", :path => "locale")
    assert_equal("all", n_("one", "two", 0))
    assert_equal("all", n_("one", "two", 1))
    assert_equal("all", n_("one", "two", 2))

    set_locale("da")
    assert_equal("da_plural", n_("one", "two", 0))
    assert_equal("da_one", n_("one", "two", 1))
    assert_equal("da_plural", n_("one", "two", 2))

    set_locale("fr")
    assert_equal("fr_one", ngettext("one", "two", 0))
    assert_equal("fr_one", ngettext("one", "two", 1))
    assert_equal("fr_plural", ngettext("one", "two", 2))

    set_locale("la")
    assert_equal("la_one", ngettext("one", "two", 21))
    assert_equal("la_one", ngettext("one", "two", 1))
    assert_equal("la_plural", ngettext("one", "two", 2))
    assert_equal("la_zero", ngettext("one", "two", 0))

    set_locale("ir")
    assert_equal("ir_one", ngettext("one", "two", 1))
    assert_equal("ir_two", ngettext("one", "two", 2))
    assert_equal("ir_plural", ngettext("one", "two", 3))
    assert_equal("ir_plural", ngettext("one", "two", 0))

    set_locale("li")
    assert_equal("li_one", ngettext("one", "two", 1))
    assert_equal("li_two", ngettext("one", "two", 22))
    assert_equal("li_three", ngettext("one", "two", 11))

    set_locale("cr")
    assert_equal("cr_one", ngettext("one", "two", 1))
    assert_equal("cr_two", ngettext("one", "two", 2))
    assert_equal("cr_three", ngettext("one", "two", 5))

    set_locale("po")
    assert_equal("po_one", ngettext("one", "two", 1))
    assert_equal("po_two", ngettext("one", "two", 2))
    assert_equal("po_three", ngettext("one", "two", 5))

    set_locale("sl")
    assert_equal("sl_one", ngettext("one", "two", 1))
    assert_equal("sl_two", ngettext("one", "two", 2))
    assert_equal("sl_three", ngettext("one", "two", 3))
    assert_equal("sl_three", ngettext("one", "two", 4))
    assert_equal("sl_four", ngettext("one", "two", 5))
  end

  def test_plural_format_invalid
    bindtextdomain("plural_error", :path => "locale")
    #If it defines msgstr[0] only, msgstr[0] is used everytime.
    assert_equal("a", n_("first", "second", 0))
    assert_equal("a", n_("first", "second", 1))
    assert_equal("a", n_("first", "second", 2))
    # Use default(plural = 0)
    set_locale("fr")
    assert_equal("fr_first", n_("first", "second", 0))
    assert_equal("fr_first", n_("first", "second", 1))
    assert_equal("fr_first", n_("first", "second", 2))
    setlocale("da") # Invalid Plural-Forms.
    assert_equal("da_first", n_("first", "second", 0))
    assert_equal("da_first", n_("first", "second", 1))
    assert_equal("da_first", n_("first", "second", 2))
    setlocale("la") # wrong number of msgstr.
    assert_equal("la_first", n_("first", "second", 0))
    assert_equal("la_first", n_("first", "second", 1))
    assert_equal("la_first", n_("first", "second", 2))

    setlocale("li") # Invalid Plural-Forms: nplurals is set, but wrong plural=.
    assert_equal("li_first", n_("first", "second", 0))
    assert_equal("li_first", n_("first", "second", 1))
    assert_equal("li_first", n_("first", "second", 2))
    assert_equal("li_one", n_("one", "two", 0))
    assert_equal("li_one", n_("one", "two", 1))
    assert_equal("li_one", n_("one", "two", 2))
  end

  def test_plural_array
    bindtextdomain("plural", :path => "locale")
    set_locale "da"
    assert_equal("da_plural", n_(["one", "two"], 0))
    assert_equal("da_one", n_(["one", "two"], 1))
    assert_equal("da_plural", n_(["one", "two"], 2))
  end

  def test_plural_with_single
    bindtextdomain("plural", :path => "locale")

    assert_equal("hitotsu", _("single"))
    assert_equal("hitotsu", n_("single", "plural", 1))
    assert_equal("hitotsu", n_("single", "plural", 2))
    assert_equal("all", n_("one", "two", 1))
    assert_equal("all", n_("one", "two", 2))
    assert_equal("all", _("one"))

    bindtextdomain("plural", :path => "locale")
    set_locale "fr"

    assert_equal("fr_hitotsu", _("single"))
    assert_equal("fr_hitotsu", n_("single", "plural", 1))
    assert_equal("fr_fukusu", n_("single", "plural", 2))
    assert_equal("fr_one", n_("one", "two", 1))
    assert_equal("fr_plural", n_("one", "two", 2))
    assert_equal("fr_one", _("one"))

#    assert_equal("fr_hitotsu", n_("single", "not match", 1))
#    assert_equal("fr_fukusu", n_("single", "not match", 2))
  end

  def test_Nn_
    GetText.locale = "da"
    bindtextdomain("plural", :path => "locale")
    assert_equal(["one", "two"], Nn_("one", "two"))
  end

  def test_setlocale
    bindtextdomain("test1", :path => "locale")
    assert_equal("japanese", _("language"))
    set_locale("en")
    assert_equal("language", _("language"))

    set_locale("fr")
    assert_equal("french", _("language"))

    set_locale(nil)
    Locale.set "en"
    assert_equal("language", _("language"))

    Locale.set "ja"
    assert_equal("japanese", _("language"))

    # Confirm to set Locale::Object.
    loc = Locale::Tag::Posix.parse("ja_JP.UTF-8")
    assert_equal(loc, GetText.locale = loc)
    assert_equal(Locale::Tag::Posix, GetText.locale.class)
  end

  def test_restrict_locale
    bindtextdomain("test1", :path => "locale")
    Locale.set_app_language_tags("ja", "en")

    Locale.set_current "fr"
    assert_equal("language", _("language"))

    Locale.set_current "en"
    assert_equal("language", _("language"))

    Locale.set_current "ja"
    assert_equal("japanese", _("language"))
    Locale.set_app_language_tags(nil)
  end


  # Anonymous
  @@anon = Module.new
  class @@anon::I
    bindtextdomain("test1", :path => "locale")
    def self.test
      _("language")
    end
    def test2
      _("language")
    end
  end

  def test_anonymous_module
    assert_equal("japanese", @@anon::I.test)
    assert_equal("japanese", @@anon::I.new.test2)

  end

  def test_frozen
    GetText.bindtextdomain("test1", :path => "locale")
    assert(GetText._("language").frozen?)
  end

end
