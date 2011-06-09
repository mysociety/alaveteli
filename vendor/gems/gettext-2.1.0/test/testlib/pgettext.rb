require 'gettext'

class TestPGetText
  include GetText
  bindtextdomain("pgettext", :path => "locale")

  def test_1
    p_("AAA", "BBB")
  end
  
  def test_2
    pgettext("AAA", "BBB")
  end

  def test_3
    pgettext("AAA|BBB", "CCC")
  end
  
  def test_4
    p_("AAA", "CCC") #not found
  end

  def test_5
    p_("CCC", "BBB")
  end

  def test_6  # not pgettext.
    _("BBB")
  end

  def with_context
    # TRANSLATORS:please translate 'name' in the context of 'program'.
    # Hint: the translation should NOT contain the translation of 'program'.
    p_('program', 'name')
  end
end
