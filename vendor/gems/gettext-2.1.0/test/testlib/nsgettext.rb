require 'gettext'

class TestNSGetText
  include GetText
  bindtextdomain("nsgettext", :path => "locale")

  def test_1
    [ns_("AAA|BBB", "CCC", 1), ns_("AAA|BBB", "CCC", 2)]
  end
  
  def test_2
    [nsgettext("AAA|BBB", "CCC", 1), nsgettext("AAA|BBB", "CCC", 2)]
  end
  
  def test_3
    [ns_("AAA", "BBB", 1), ns_("AAA", "BBB", 2)] #not found
  end

  def test_4
    [ns_("AAA|CCC", "DDD", 1), ns_("AAA|CCC", "DDD", 2)] #not found
  end

  def test_5
    [ns_("AAA|BBB|CCC", "DDD", 1), ns_("AAA|BBB|CCC", "DDD", 2)] #not found
  end

  def test_6
    [ns_("AAA$BBB", "CCC", 1, "$"), ns_("AAA$BBB", "CCC", 2, "$")] #not found
  end

  def test_7
    [ns_("AAA$B|BB", "CCC", 1, "$"), ns_("AAA$B|BB", "CCC", 2, "$")] #not found
  end

  def test_8
    [ns_("AAA$B|CC", "DDD", 1, "$"), ns_("AAA$B|CC", "DDD", 2, "$")]
  end

  def test_9
    [ns_("AAA|CCC|BBB", "DDD", 1), ns_("AAA|CCC|BBB", "DDD", 2)] #not found
  end
end
