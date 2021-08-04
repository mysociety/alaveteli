require 'spec_helper'
require 'alaveteli_external_command'

RSpec.describe "when running external commands" do

  let(:script_dir) do
    File.join(File.dirname(__FILE__), 'alaveteli_external_command_scripts')
  end
  let(:segfault_script) { File.join(script_dir, 'segfault.sh') }
  let(:error_script) { File.join(script_dir, 'error.sh') }

  describe '#run!' do

    it 'should raise Error for a non-zero exit status' do
      expect { AlaveteliExternalCommand.run!(error_script) }.to raise_error(
        AlaveteliExternalCommand::Error
      )
    end

    it 'should raise Crash when an external command crashes' do
      expect { AlaveteliExternalCommand.run!(segfault_script) }.to raise_error(
        AlaveteliExternalCommand::Crash
      )
    end

  end

  describe '#run' do

    it 'should return nil for a non-zero exit status' do
      expect($stderr).to receive(:puts).with(/error from command/)
      expect(AlaveteliExternalCommand.run(error_script)).to be_nil
    end

    it 'should return nil when an external command crashes' do
      expect($stderr).to receive(:puts).with(/exited abnormally/)
      expect(AlaveteliExternalCommand.run(segfault_script)).to be_nil
    end

  end

end
