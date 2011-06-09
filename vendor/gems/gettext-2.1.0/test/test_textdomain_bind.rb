require 'testlib/helper.rb'

class Foo
end

class TestGetTextBind < Test::Unit::TestCase
  def setup
    GetText.locale = "ja_JP.EUC-JP"
    GetText::TextDomainManager.clear_all_textdomains
  end

  def test_bindtextdomain
    domain = GetText.bindtextdomain("foo")
    assert_equal domain, GetText::TextDomainManager.create_or_find_textdomain_group(Object).textdomains[0]
    assert_equal domain, GetText::TextDomainManager.textdomain_pool("foo")
  end

  def test_textdomain
    domain1 = GetText.bindtextdomain("foo")

    assert_equal domain1, GetText.textdomain("foo")

    assert_raise(GetText::NoboundTextDomainError) {
      GetText.textdomain_to(Foo, "bar")
    }
  end

  def test_textdomain_to
    domain1 = GetText.bindtextdomain("foo")

    assert_equal domain1, GetText.textdomain_to(Foo, "foo")

    assert_raise(GetText::NoboundTextDomainError) {
      GetText.textdomain_to(Foo, "bar")
    }
  end
end
