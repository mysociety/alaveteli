require 'gettext'

class TestNPGetText
  include GetText
  bindtextdomain("npgettext", :path => "locale")

  def test_1
    [np_("Magazine", "a book", "%{num} books", 1), 
     np_("Magazine", "a book", "%{num} books", 2)]
  end
  
  def test_2
    [npgettext("Magazine", "a book", "%{num} books", 1), 
     npgettext("Magazine", "a book", "%{num} books", 2)]
  end
  
  def test_3
    [np_("Hardcover", "a book", "%{num} books", 1), 
     np_("Hardcover", "a book", "%{num} books", 2)]
  end

  def test_4
    [np_("Magaine", "I have a magazine", "I have %{num} magazines", 1), 
     np_("Magaine", "I have a magazine", "I have %{num} magazines", 2)]
  end

  def test_5
    [np_("Hardcover", "a picture", "%{num} pictures", 1), 
     np_("Hardcover", "a picture", "%{num} pictures", 2)]  #not found.
  end
end
