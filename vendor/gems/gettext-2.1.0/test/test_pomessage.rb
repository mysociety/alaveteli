require 'testlib/helper.rb'
require 'gettext/tools/parser/ruby'

# Most functionality of PoMessage is thoroughly tested together 
# with the parser and po file generator. Here only tests for some special 
# functionality.
class TestPoMessage < Test::Unit::TestCase

  def test_context_match
    tt1 = GetText::PoMessage.new(:msgctxt)
    tt1.msgid = 'hello'
    tt1.msgctxt = 'world'
    tt2 = GetText::PoMessage.new(:normal)
    tt2.msgid = 'hello'
    assert_raise GetText::ParseError do
      tt1.merge tt2
    end
  end

  def test_attribute_accumulation
    tt = GetText::PoMessage.new(:plural)
    tt.set_current_attribute 'long'
    tt.set_current_attribute ' tail'
    tt.advance_to_next_attribute
    tt.set_current_attribute 'long tails'
    assert_equal 'long tail', tt.msgid
    assert_equal 'long tails', tt.msgid_plural
  end

  def test_to_po_str_normal
    po = GetText::PoMessage.new(:normal)
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "\n#: file1:1 file2:10\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_po_str

    po.msgctxt = 'context'
    po.msgid_plural = 'hello2'
    # Ignore these properties.
    assert_equal "\n#: file1:1 file2:10\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_po_str
  end

  def test_to_po_str_plural
    po = GetText::PoMessage.new(:plural)
    po.msgid = 'hello'
    po.msgid_plural = 'hello2'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "\n#: file1:1 file2:10\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_po_str

    po.msgctxt = 'context'
    # Ignore this property
    assert_equal "\n#: file1:1 file2:10\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_po_str
  end

  def test_to_po_str_msgctxt
    po = GetText::PoMessage.new(:msgctxt)
    po.msgctxt = 'context'
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "\n#: file1:1 file2:10\nmsgctxt \"context\"\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_po_str
  end

  def test_to_po_str_msgctxt_plural
    po = GetText::PoMessage.new(:msgctxt_plural)
    po.msgctxt = 'context'
    po.msgid = 'hello'
    po.msgid_plural = 'hello2'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "\n#: file1:1 file2:10\nmsgctxt \"context\"\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_po_str
  end

  def test_to_po_str_exception
    po = GetText::PoMessage.new(:normal)
    po.sources = ["file1:1", "file2:10"]
    assert_raise(RuntimeError){ po.to_po_str }

    po.sources = nil
    assert_raise(RuntimeError){ po.to_po_str }

    po = GetText::PoMessage.new(:plural)
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_raise(RuntimeError){ po.to_po_str }

    po.msgid_plural = 'hello2'
    po.sources = nil
    assert_raise(RuntimeError){ po.to_po_str }

    po = GetText::PoMessage.new(:msgctxt)
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_raise(RuntimeError){ po.to_po_str }

    po = GetText::PoMessage.new(:msgctxt_plural)
    po.msgctxt = 'context'
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_raise(RuntimeError){ po.to_po_str }
  end
end
