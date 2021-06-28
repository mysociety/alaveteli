require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AlaveteliRateLimiter::Backends::PStoreDatabase do

  let(:test_path) { Rails.root + '/tmp/test.pstore' }

  after(:each) do
    File.delete(test_path) if File.exist?(test_path)
  end

  describe '.new' do

    it 'requires a path' do
      expect { subject }.to raise_error(KeyError)
    end

    it 'initializes a PStore at the given path' do
      path = Pathname.new("#{ Rails.root }/tmp/custom_database.pstore")
      subject = described_class.new(:path => path)
      expect(subject.pstore.path).to eq(path)
    end

    it 'converts a string path to a pathname' do
      path = "#{ Rails.root }/tmp/custom_database.pstore"
      subject = described_class.new(:path => path)
      expect(subject.pstore.path).to eq(Pathname.new(path))
    end

  end

  describe '#get' do

    it 'returns the values for the key' do
      subject = described_class.new(:path => test_path)

      expected = [Time.zone.parse('2016-10-21'),
                  Time.zone.parse('2016-10-21'),
                  Time.zone.parse('2016-10-21')]

      subject.set('key', expected)

      expect(subject.get('key')).to eq(expected)
    end

    it 'only includes values recorded for the given key' do
      subject = described_class.new(:path => test_path)

      expected = [Time.zone.parse('2016-10-21'),
                  Time.zone.parse('2016-10-21'),
                  Time.zone.parse('2016-10-21')]

      unexpected = [Time.zone.parse('2016-09-21')]

      subject.set('key1', expected)
      subject.set('key2', unexpected)

      expect(subject.get('key1')).to eq(expected)
    end

  end

  describe '#set' do

    it 'sets a new record for the given keys' do
      subject = described_class.new(:path => test_path)
      subject.set('key', [])
      expect(subject.get('key')).to eq([])
    end

    it 'overrides the records for the given keys' do
      subject = described_class.new(:path => test_path)

      subject.record('key')
      subject.record('key')
      subject.record('key')
      expected = [Time.zone.parse('2016-10-21')]
      subject.set('key', expected)

      expect(subject.get('key')).to eq(expected)
    end

  end

  describe '#record' do

    it 'records an event for a given IP and event' do
      subject = described_class.new(:path => test_path)
      time = Time.zone.now.to_datetime

      travel_to(time) do
        subject.record('key')
        expect(subject.get('key').last).to be_within(1.second).of(time)
      end
    end

  end

  describe '#==' do

    it 'is equal if the pstore paths are the same' do
      subject = described_class.new(:path => test_path)
      expect(subject).to eq(subject.dup)
    end

    it 'is not equal if the pstore paths are different' do
      subject = described_class.new(:path => test_path)
      path = "#{ Rails.root }/tmp/custom_database.pstore"
      expect(subject).not_to eq(described_class.new(:path => path))
    end

  end

  describe '#destroy' do

    it 'destroys the pstore' do
      subject = described_class.new(:path => test_path)
      subject.set('1', '2')
      subject.destroy
      expect(File.exist?(test_path)).to eq(false)
    end

    it 'does not attempt to destroy the pstore if it does not yet exist' do
      subject = described_class.new(:path => test_path)
      expect { subject.destroy }.not_to raise_error
    end

  end

end
