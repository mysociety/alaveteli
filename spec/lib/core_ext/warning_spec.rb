require 'spec_helper'

describe Warning do
  describe '.with_raised_warnings' do
    it 'makes .warn raise' do
      expect {
        described_class.with_raised_warnings { Warning.warn('foo') }
      }.to raise_error(RaisedWarning)
    end

    it 'only affects calls to .warn within the block' do
      expect { Warning.warn('bar') }.to output('bar').to_stderr
    end
  end
end
