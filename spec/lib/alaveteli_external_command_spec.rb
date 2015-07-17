# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'alaveteli_external_command'

script_dir = File.join(File.dirname(__FILE__), 'alaveteli_external_command_scripts')
segfault_script = File.join(script_dir, 'segfault.sh')
error_script = File.join(script_dir, 'error.sh')

describe "when running external commands" do

  it "should detect a non-zero exit status" do
    $stderr.should_receive(:puts).with(/Error from/)
    t = AlaveteliExternalCommand.run(error_script)
    assert_nil t
  end

  it "should detect when an external command crashes" do
    $stderr.should_receive(:puts).with(/exited abnormally/)
    t = AlaveteliExternalCommand.run(segfault_script)
    assert_nil t
  end

end
