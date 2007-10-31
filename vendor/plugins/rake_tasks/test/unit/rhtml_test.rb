require 'test/unit'
require '../../lib/convert'

class MoverTest < Test::Unit::TestCase
  def setup
    Convert.view_path = '../fixtures/views/'
    
    @rhtml = File.expand_path('../fixtures/views/tests/test.rhtml')
    @erb   = @rhtml.gsub('.rhtml', '.erb')
  end
  
  def teardown
    Dir.glob(File.join(Convert.view_path, '**', '*.erb')) do |file|
      mv_file = file.gsub('.erb', '.rhtml')
      system "mv #{file} #{mv_file}"
    end
  end
  
  def test_should_find_files_with_rhtml_extension
    assert_equal 1, Convert::Mover.find(:rhtml).size
  end
  
  def test_should_output_svn_system_call_text
    rhtml_files = Convert::Mover.find :rhtml
    assert_equal "mv #{@rhtml} #{@erb}", rhtml_files.first.move_command(:erb)
    assert_equal "svn mv #{@rhtml} #{@erb}", rhtml_files.first.move_command(:erb, :scm => :svn)
  end
  
  def test_should_move_files_locally
    assert File.exist?(@rhtml)
    assert !File.exist?(@erb)
    
    rhtml_files = Convert::Mover.find :rhtml
    rhtml_files.first.move(:erb)
    
    assert !File.exist?(@rhtml)
    assert File.exist?(@erb)
  end
end