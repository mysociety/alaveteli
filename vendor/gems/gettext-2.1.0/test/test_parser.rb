require 'testlib/helper.rb'
require 'gettext/tools/parser/ruby'
require 'gettext/tools/parser/glade'
require 'gettext/tools/parser/erb'

require 'gettext/tools/rgettext'

class TestGetTextParser < Test::Unit::TestCase
  def test_ruby
    @ary = GetText::RGetText.parse('testlib/gettext.rb')

    assert_target 'aaa', ['testlib/gettext.rb:8']
    assert_target 'aaa\n', ['testlib/gettext.rb:12']
    assert_target 'bbb\nccc', ['testlib/gettext.rb:16']
    assert_target 'bbb\nccc\nddd\n', ['testlib/gettext.rb:20']
    assert_target 'eee', ['testlib/gettext.rb:27', 'testlib/gettext.rb:31']
    assert_target 'fff', ['testlib/gettext.rb:31']
    assert_target 'ggghhhiii', ['testlib/gettext.rb:35']
    assert_target 'a"b"c"', ['testlib/gettext.rb:41']
    assert_target 'd"e"f"', ['testlib/gettext.rb:45']
    assert_target 'jjj', ['testlib/gettext.rb:49']
    assert_target 'kkk', ['testlib/gettext.rb:50']
    assert_target 'lllmmm', ['testlib/gettext.rb:54']
    assert_target 'nnn\nooo', ['testlib/gettext.rb:62']
    assert_target "\#", ['testlib/gettext.rb:66', 'testlib/gettext.rb:70']
    assert_target "\\taaa", ['testlib/gettext.rb:74']
    assert_target "Here document1\\nHere document2\\n", ['testlib/gettext.rb:78']
    assert_target "Francois Pinard", ['testlib/gettext.rb:97'] do |t|
      assert_match /proper name/, t.comment
      assert_match /Pronunciation/, t.comment
    end
    assert_target "self explaining", ['testlib/gettext.rb:102'] do |t|
      assert_nil t.comment
    end
    # TODO: assert_target "in_quote", ['testlib/gettext.rb:96']
  end

  def test_ruby_N
    @ary = GetText::RGetText.parse('testlib/N_.rb')

    assert_target 'aaa', ['testlib/N_.rb:8']
    assert_target 'aaa\n', ['testlib/N_.rb:12']
    assert_target 'bbb\nccc', ['testlib/N_.rb:16']
    assert_target 'bbb\nccc\nddd\n', ['testlib/N_.rb:20']
    assert_target 'eee', ['testlib/N_.rb:27', 'testlib/N_.rb:31']
    assert_target 'fff', ['testlib/N_.rb:31']
    assert_target 'ggghhhiii', ['testlib/N_.rb:35']
    assert_target 'a"b"c"', ['testlib/N_.rb:41']
    assert_target 'd"e"f"', ['testlib/N_.rb:45']
    assert_target 'jjj', ['testlib/N_.rb:49']
    assert_target 'kkk', ['testlib/N_.rb:50']
    assert_target 'lllmmm', ['testlib/N_.rb:54']
    assert_target 'nnn\nooo', ['testlib/N_.rb:62']
  end

  def test_ruby_n
    @ary = GetText::RGetText.parse('testlib/ngettext.rb')
    assert_plural_target "aaa", "aaa2", ['testlib/ngettext.rb:8']
    assert_plural_target "bbb\\n", "ccc2\\nccc2", ['testlib/ngettext.rb:12']
    assert_plural_target "ddd\\nddd", "ddd2\\nddd2", ['testlib/ngettext.rb:16']
    assert_plural_target "eee\\neee\\n", "eee2\\neee2\\n", ['testlib/ngettext.rb:21']
    assert_plural_target "ddd\\neee\\n", "ddd\\neee2", ['testlib/ngettext.rb:27']
    assert_plural_target "fff", "fff2", ['testlib/ngettext.rb:34', 'testlib/ngettext.rb:38']
    assert_plural_target "ggg", "ggg2", ['testlib/ngettext.rb:38']
    assert_plural_target "ggghhhiii", "jjjkkklll", ['testlib/ngettext.rb:42']
    assert_plural_target "a\"b\"c\"", "a\"b\"c\"2", ['testlib/ngettext.rb:51']
    assert_plural_target "mmmmmm", "mmm2mmm2", ['testlib/ngettext.rb:59']
    assert_plural_target "nnn", "nnn2", ['testlib/ngettext.rb:60']
    assert_plural_target "comment", "comments", ['testlib/ngettext.rb:76'] do |t|
      assert_equal "please provide translations for all \n the plural forms!", t.comment
    end
  end
  
  def test_ruby_p
    @ary = GetText::RGetText.parse('testlib/pgettext.rb')
    assert_target_in_context "AAA", "BBB", ["testlib/pgettext.rb:8", "testlib/pgettext.rb:12"]
    assert_target_in_context "AAA|BBB", "CCC", ["testlib/pgettext.rb:16"]
    assert_target_in_context "AAA", "CCC", ["testlib/pgettext.rb:20"]
    assert_target_in_context "CCC", "BBB", ["testlib/pgettext.rb:24"]
    assert_target_in_context "program", "name", ['testlib/pgettext.rb:34'] do |t|
      assert_equal "please translate 'name' in the context of 'program'.\n Hint: the translation should NOT contain the translation of 'program'.", t.comment
    end
  end

  def test_glade
    # Old style (~2.0.4)
    ary = GetText::GladeParser.parse('testlib/gladeparser.glade')

    assert_equal(['window1', 'testlib/gladeparser.glade:8'], ary[0])
    assert_equal(['normal text', 'testlib/gladeparser.glade:29'], ary[1])
    assert_equal(['1st line\n2nd line\n3rd line', 'testlib/gladeparser.glade:50'], ary[2])
    assert_equal(['<span color="red" weight="bold" size="large">markup </span>', 'testlib/gladeparser.glade:73'], ary[3])
    assert_equal(['<span color="red">1st line markup </span>\n<span color="blue">2nd line markup</span>', 'testlib/gladeparser.glade:94'], ary[4])
    assert_equal(['<span>&quot;markup&quot; with &lt;escaped strings&gt;</span>', 'testlib/gladeparser.glade:116'], ary[5])
    assert_equal(['duplicated', 'testlib/gladeparser.glade:137', 'testlib/gladeparser.glade:158'], ary[6])
  end

  def testlib_erb
    @ary = GetText::ErbParser.parse('testlib/erb.rhtml')

    assert_target 'aaa', ['testlib/erb.rhtml:8']
    assert_target 'aaa\n', ['testlib/erb.rhtml:11']
    assert_target 'bbb', ['testlib/erb.rhtml:12']
    assert_plural_target "ccc1", "ccc2", ['testlib/erb.rhtml:13']
  end

  def test_rgettext_parse
    GetText::ErbParser.init(:extnames => ['.rhtml', '.rxml'])
    @ary = GetText::RGetText.parse(['testlib/erb.rhtml'])
    assert_target 'aaa', ['testlib/erb.rhtml:8']
    assert_target 'aaa\n', ['testlib/erb.rhtml:11']
    assert_target 'bbb', ['testlib/erb.rhtml:12']
    assert_plural_target "ccc1", "ccc2", ['testlib/erb.rhtml:13']

    @ary = GetText::RGetText.parse(['testlib/erb.rxml'])
    assert_target 'aaa', ['testlib/erb.rxml:9']
    assert_target 'aaa\n', ['testlib/erb.rxml:12']
    assert_target 'bbb', ['testlib/erb.rxml:13']
    assert_plural_target "ccc1", "ccc2", ['testlib/erb.rxml:14']

    @ary = GetText::RGetText.parse(['testlib/ngettext.rb'])
    assert_plural_target "ooo", "ppp", ['testlib/ngettext.rb:64', 'testlib/ngettext.rb:65']
    assert_plural_target "qqq", "rrr", ['testlib/ngettext.rb:69', 'testlib/ngettext.rb:70']
  end

  private

  def assert_target(msgid, sources = nil)
    t = @ary.detect {|elem| elem.msgid == msgid}
    if t
      if sources
        assert_equal sources.sort, t.sources.sort, 'Translation target sources do not match.'
      end
      yield t if block_given?
    else
      flunk "Expected a translation target with id '#{msgid}'. Not found."
    end
  end

  def assert_plural_target(msgid, plural, sources = nil)
    assert_target msgid, sources do |t|
      assert_equal plural, t.msgid_plural, 'Expected plural form'
      yield t if block_given?
    end
  end

  def assert_target_in_context(msgctxt, msgid, sources = nil)
    t = @ary.detect {|elem| elem.msgid == msgid && elem.msgctxt == msgctxt}
    if t
      if sources
        assert_equal sources.sort, t.sources.sort, 'Translation target sources do not match.'
      end
      yield t if block_given?
    else
      flunk "Expected a translation target with id '#{msgid}' and context '#{msgctxt}'. Not found."
    end
  end
end
