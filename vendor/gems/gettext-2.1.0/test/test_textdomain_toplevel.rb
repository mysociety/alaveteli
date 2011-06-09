require 'testlib/helper.rb'
include GetText

bindtextdomain("test1", :path => "locale")
module M1
  module_function
  def module_function
    _("language")
  end
end

class C1
  def instance_method
    _("language")
  end
  def self.class_method
    _("language")
  end
end

def toplevel_method
  _("language")
end

class TestGetText < Test::Unit::TestCase
  include GetText

  def test_toplevel
    GetText.locale = "ja"
    assert_equal("japanese", toplevel_method)
    assert_equal("japanese", M1.module_function)
    assert_equal("japanese", C1.class_method)
    assert_equal("japanese", C1.new.instance_method)

    GetText::TextDomainManager.clear_all_textdomains
    GetText.bindtextdomain("test1", :path => "locale")
    assert_equal("japanese", toplevel_method)
    assert_equal("japanese", M1.module_function)
    assert_equal("japanese", C1.class_method)
    assert_equal("japanese", C1.new.instance_method)
  end
end
