require 'gettext'
include GetText

class TestRubyParser_n
  bindtextdomain("rubyparser", :path => "locale")

  def test_1
    n_("aaa","aaa2",1)
  end

  def test_2
    n_("bbb\n", "ccc2\nccc2", 1)
  end

  def test_3_1
    n_("ddd\nddd", 
	"ddd2\nddd2", 
	1)
  end
  def test_3_2
    n_("eee\neee\n" ,
       "eee2\neee2\n" , 
       1)
  end

  def test_4
     n_("ddd
eee
", "ddd
eee2", 1)
  end

  def test_5_1
    n_("fff", "fff2", 1)
  end

  def test_5_2
    n_("fff", "fff2", 1) + "foo" + n_("ggg", "ggg2", 1)
  end

  def test_6
    n_("ggg"\
      "hhh"\
      "iii",
       "jjj"\
       "kkk"\
       "lll", 1)
  end

  def test_7
    n_('a"b"c"', 'a"b"c"2', 1)
  end

  def test_8
    n_("d\"e\"f\"", "d\"e\"f\"2", 1)
  end

  def test_9
    n_("mmm" + "mmm","mmm2" + "mmm2",1) + 
    n_("nnn" ,"nnn2" ,1)
  end

  def test_10
    _("ooo")
    n_("ooo", "ppp", 1)
  end

  def test_11
    n_("qqq", "rrr", 1) 
    n_("qqq", "sss", 1)  # This is merged to "qqq" with plural form "rrr".
  end

  def extracted_comments
    # TRANSLATORS:please provide translations for all 
    # the plural forms!
    n_('comment', 'comments', 2)
  end
end
    
