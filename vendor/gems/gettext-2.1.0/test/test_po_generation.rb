require 'testlib/helper.rb'
require 'gettext'
require 'gettext/tools/rgettext.rb'
require 'stringio'

class TestPoGeneration < Test::Unit::TestCase
  def test_extracted_comments
    GetText::RGetText.run(
      File.join(File.dirname(__FILE__), 'testlib/gettext.rb'), 
      out = StringIO.new)
    res = out.string

    # Use following to debug the content of the
    # created file: File.open('/tmp/test.po', 'w').write(res)

    assert_match '#. "Fran\u00e7ois" or (with HTML entities) "Fran&ccedil;ois".', res
    assert_no_match /Ignored/, res, 'Only comments starting with TRANSLATORS should be extracted'
    assert_no_match /TRANSLATORS: This is a proper name/, res, 'The prefix "TRANSLATORS:" should be skipped'
  end
end
