require 'testlib/helper'

require 'gettext/tools'
class TestToolsTools < Test::Unit::TestCase
  def setup
    FileUtils.cp_r "tools/files", "tools/test_files"
  end
  def teardown
    FileUtils.rm_rf "tools/test_files"
  end

  def test_msgmerge_merges_old_and_new_po_file
    GetText.msgmerge(path('simple_1.po'),path('simple_2.po'),'X',:msgmerge=>[:sort_output,:no_location])
    assert_equal File.read(path('simple_1.po')), <<EOF
msgid "a"
msgstr "b"

#~ msgid "x"
#~ msgstr "y"
EOF
  end

  def test_msgmerge_inserts_the_new_version
    old = backup('version.po')
    GetText.msgmerge(old,path('version.po'),'NEW')
    assert File.read(old) =~ /"Project-Id-Version: NEW\\n"/
  end

  def test_update_pofiles_updates_a_single_language
    GetText.update_pofiles('app',[path('simple_translation.rb')],'x',:po_root=>path('.'),:lang=>'en',:msgmerge=>[:no_location])
    text = <<EOF
msgid "a translation"
msgstr ""
EOF
    assert_equal text, File.read(path('app.pot'))
    assert_equal text, File.read(path('en/app.po'))
    assert_equal '', File.read(path('de/app.po'))
  end

  def test_update_pofiles_updates_creates_po_folder_if_missing
    GetText.update_pofiles('app',[path('simple_translation.rb')],'x',:po_root=>path('./xx'))
    assert File.exist?(path('xx/app.pot'))
  end

  def test_create_mofiles_generates_mo_for_each_po
    GetText.create_mofiles(:po_root=>path('.'),:mo_root=>path('mo'))
    assert File.exist?(path('mo/en/LC_MESSAGES/app.mo'))
    assert File.exist?(path('mo/de/LC_MESSAGES/app.mo'))
  end
private

  def backup(name)
    copy = path(name+".bak")
    FileUtils.cp path(name), copy
    copy
  end

  def path(name)
    File.join(File.dirname(__FILE__),'test_files',name)
  end
end