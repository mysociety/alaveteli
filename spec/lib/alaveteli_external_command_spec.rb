require 'spec_helper'
require 'alaveteli_external_command'

script_dir = File.join(File.dirname(__FILE__), 'alaveteli_external_command_scripts')
segfault_script = File.join(script_dir, 'segfault.sh')
error_script = File.join(script_dir, 'error.sh')

RSpec.describe AlaveteliExternalCommand do
  describe 'initialisation' do
    let(:command) { described_class.new('ls') }

    it 'accepts program name attribute' do
      expect(command.program_name).to eq('ls')
    end
  end

  describe '#run' do
    subject { command.run }

    before { allow($stderr).to receive(:puts) }

    context 'when command has arguments and returns output' do
      subject { command.run('-n', 'foobar') }

      let(:command) { described_class.new('echo') }

      it { is_expected.to eq('foobar') }

      it 'does not outputs to standard error' do
        expect($stderr).to_not receive(:puts)
        command.run
      end
    end

    context 'when command is missing' do
      let(:command) { described_class.new('missing_command') }

      it 'raises runtime error' do
        expect { command.run }.to raise_error(
          RuntimeError, /Could not find missing_command/
        )
      end
    end

    context 'when command returned non-zero exit status' do
      let(:command) { described_class.new(error_script) }

      it { is_expected.to be_nil }

      it 'outputs to standard error' do
        expect($stderr).to receive(:puts).with(/Error from/)
        command.run
      end
    end

    context 'when command crashes' do
      let(:command) { described_class.new(segfault_script) }

      it { is_expected.to be_nil }

      it 'outputs to standard error' do
        expect($stderr).to receive(:puts).with(/exited abnormally/)
        command.run
      end
    end
  end

  describe '#exist?' do
    subject { command.exist? }

    context 'when command is present' do
      let(:command) { described_class.new('echo') }
      it { is_expected.to eq true }
    end

    context 'when command is missing' do
      let(:command) { described_class.new('missing_command') }
      it { is_expected.to eq false }
    end
  end
end

RSpec.describe "when running external commands" do

  it "should detect a non-zero exit status" do
    expect($stderr).to receive(:puts).with(/Error from/)
    t = AlaveteliExternalCommand.run(error_script)
    assert_nil t
  end

  it "should detect when an external command crashes" do
    expect($stderr).to receive(:puts).with(/exited abnormally/)
    t = AlaveteliExternalCommand.run(segfault_script)
    assert_nil t
  end

end
