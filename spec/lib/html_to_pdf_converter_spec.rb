require 'spec_helper'

RSpec.describe HTMLtoPDFConverter do
  shared_context :valid_command do
    before do
      allow(described_class).to receive(:base_command).and_return(
        AlaveteliExternalCommand.new('echo')
      )
      allow(described_class).to receive(:version).and_return(
        Gem::Version.new('0.11')
      )
    end
  end

  shared_context :valid_command_with_args do
    before do
      allow(described_class).to receive(:base_command).and_return(
        AlaveteliExternalCommand.new('echo').add_args('-n')
      )
      allow(described_class).to receive(:version).and_return(
        Gem::Version.new('0.11')
      )
    end
  end

  shared_context :valid_command_v0_12 do
    before do
      allow(described_class).to receive(:base_command).and_return(
        AlaveteliExternalCommand.new('echo').add_args('-n')
      )
      allow(described_class).to receive(:version).and_return(
        Gem::Version.new('0.12')
      )
    end
  end

  shared_context :invalid_command do
    before do
      allow(described_class).to receive(:base_command).and_return(
        AlaveteliExternalCommand.new('invalid')
      )
      allow(described_class).to receive(:version).and_return(
        Gem::Version.new('0.11')
      )
    end
  end

  describe '.command' do
    subject { described_class.command }

    context 'when command exists' do
      include_context :valid_command
      it { is_expected.to be_a(AlaveteliExternalCommand) }
    end

    context 'when command does not exist' do
      include_context :invalid_command
      it { is_expected.to be_a(AlaveteliExternalCommand) }
    end

    context 'when version less than 0.12' do
      include_context :valid_command

      it 'does not add command arguments' do
        expect(subject.command_args).to be_nil
      end
    end

    context 'when version greater or equal to 0.12' do
      include_context :valid_command_v0_12

      it 'add command arguments' do
        expect(subject.command_args).to match_array(
          [
            '--enable-local-file-access',
            '--no-images',
            '--load-media-error-handling', 'ignore',
            '--load-error-handling', 'skip'
          ]
        )
      end
    end
  end

  describe '.exist?' do
    subject { described_class.exist? }

    context 'when command exists' do
      include_context :valid_command
      it { is_expected.to eq true }
    end

    context 'when command does not exist' do
      include_context :invalid_command
      it { is_expected.to eq false }
    end
  end

  shared_context :instance do
    let(:options) { ['-n'] }
    let(:input) { double(:io, path: './in') }
    let(:output) { double(:io, path: './out') }
    let(:args) { [*options, input, output] }
    let(:instance) { described_class.new(*args) }
  end

  describe '#run' do
    include_context :instance
    subject { instance.run }

    context 'when command exists' do
      include_context :valid_command

      it 'calls run to command with options and input, output file paths' do
        expect(described_class.command).to receive(:run).with(
          *options, './in', './out'
        )
        subject
      end

      it 'runs the command' do
        expect(subject).to eq './in ./out'
      end
    end

    context 'when command exists' do
      include_context :invalid_command

      it 'calls run to command with options and input, output file paths' do
        expect(described_class.command).to receive(:run).with(
          *options, './in', './out'
        )
        subject
      end

      it 'raises Alaveteli external command error' do
        expect { subject }.to raise_error(/Could not find invalid/)
      end
    end
  end

  describe '#to_s' do
    include_context :instance
    subject { instance.to_s }

    context 'when command exists' do
      include_context :valid_command

      it 'returns full command string' do
        expect(subject).to eq 'echo -n ./in ./out'
      end
    end

    context 'when command already has arguments' do
      include_context :valid_command_with_args

      it 'returns full command string' do
        expect(subject).to eq 'echo -n -n ./in ./out'
      end
    end

    context 'when command exists' do
      include_context :invalid_command

      it 'returns full command string' do
        expect(subject).to eq 'invalid -n ./in ./out'
      end
    end
  end
end
