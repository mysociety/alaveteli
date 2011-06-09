# encoding: UTF-8

require 'locale/tag'
require 'locale/taglist'
require 'test/unit'

class TestTagList < Test::Unit::TestCase
  def test_taglist_posix
    list = Locale::TagList.new([Locale::Tag.parse("ja_JP.eucJP@mobile"), 
				Locale::Tag.parse("en_US.iso8859-1")])

    assert_equal "ja", list.language
    assert_equal "JP", list.region
    assert_equal "eucJP", list.charset
    assert_equal "mobile", list.modifier
    assert_equal "ja_JP.eucJP@mobile", list.to_s
    assert_equal Locale::Tag::Common.parse("ja_JP_mobile"), list.to_common
    assert_equal Locale::Tag::Rfc.parse("ja-JP-mobile"), list.to_rfc
    assert_equal Locale::Tag::Cldr.parse("ja_JP_mobile"), list.to_cldr
    assert_equal Locale::Tag::Posix.parse("ja_JP.eucJP@mobile"), list.to_posix
    assert_equal Locale::Tag::Posix.parse("en_US.iso8859-1"), list[1]
  end

  def test_taglist_rfc
    list = Locale::TagList.new([Locale::Tag.parse("ja-Hira-JP-MOBILE-y-aaa-x-bbb"), 
				Locale::Tag.parse("en-US-mobile")])
    assert_equal "ja", list.language
    assert_equal "Hira", list.script
    assert_equal "JP", list.region
    assert_equal ["MOBILE"], list.variants
    assert_equal ["y-aaa"], list.extensions
    assert_equal "x-bbb", list.privateuse
  end
end
