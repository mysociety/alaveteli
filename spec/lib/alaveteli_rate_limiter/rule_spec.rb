require 'spec_helper'

describe AlaveteliRateLimiter::Rule do

  describe '.from_hash' do

    it 'constructs a Rule with associated Window from a Hash' do
      attrs =  { :name => :test,
                 :count => 2,
                 :window => { :value => 1, :unit => :hour } }
      window = AlaveteliRateLimiter::Window.new(1, :hour)
      expected = described_class.new(:test, 2, window)
      expect(described_class.from_hash(attrs)).to eq(expected)
    end

    it 'requires a :name key' do
      expect { described_class.from_hash({}) }.to raise_error(KeyError)
    end

    it 'requires a :count key' do
      expect { described_class.from_hash(:name => :test) }.
        to raise_error(KeyError)
    end

    it 'requires a :window key' do
      expect { described_class.from_hash(:name => :test, :count => 1) }.
        to raise_error(KeyError)
    end

    it 'requires a :window hash with a :value key' do
      attrs = { :name => :test, :count => 1, :window => { :unit => :hour } }
      expect { described_class.from_hash(attrs) }.to raise_error(KeyError)
    end

    it 'requires a :window hash with a :unit key' do
      attrs = { :name => :test, :count => 1, :window => { :value => 1 } }
      expect { described_class.from_hash(attrs) }.to raise_error(KeyError)
    end

  end

  describe '.new' do

    it 'requires a name' do
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'requires a name that can be converted in to a Symbol' do
      expect { described_class.new(1, 1, double) }.to raise_error(NoMethodError)
    end

    it 'requires a count' do
      expect { described_class.new(:test) }.to raise_error(ArgumentError)
    end

    it 'requires a window' do
      expect { described_class.new(:test, 1) }.to raise_error(ArgumentError)
    end

    it 'requires count to be numeric' do
      expect { described_class.new(:test, 'hello', double) }.
        to raise_error(ArgumentError)
    end

    it 'converts a numeric count to an Integer' do
      expect(described_class.new(:test, '1', double).count).to eq(1)
    end

  end

  describe '#limit?' do

    it 'returns true if the given records are over the limit' do
      records = [10, 5, 1].map { |i| i.minutes.ago }
      attrs = { :name => :test,
                :count => 2,
                :window => { :value => 1, :unit => :hour } }
      subject = described_class.from_hash(attrs)
      expect(subject.limit?(records)).to eq(true)
    end

    it 'returns false if the given records are under the limit' do
      records = [10, 5, 1].map { |i| i.minutes.ago }
      attrs = { :name => :test,
                :count => 20,
                :window => { :value => 1, :unit => :hour } }
      subject = described_class.from_hash(attrs)
      expect(subject.limit?(records)).to eq(false)
    end

    it 'does not matter if the records are in a different order' do
      records = [5, 10, 1].map { |i| i.minutes.ago }
      attrs = { :name => :test,
                :count => 2,
                :window => { :value => 1, :unit => :hour } }
      subject = described_class.from_hash(attrs)
      expect(subject.limit?(records.shuffle)).to eq(true)
    end

    it 'returns false if no records are given' do
      attrs = { :name => :test,
                :count => 20,
                :window => { :value => 1, :unit => :hour } }
      subject = described_class.from_hash(attrs)
      expect(subject.limit?([])).to eq(false)
    end

  end

  describe '#records_in_window' do

    it 'returns records in the window' do
      records = [1, 5, 10].map { |i| i.days.ago }
      attrs = { :name => :test,
                :count => 20,
                :window => { :value => 7, :unit => :day } }
      subject = described_class.from_hash(attrs)
      expected = records[0..1]
      expect(subject.records_in_window(records)).to eq(expected)
    end

  end

  describe '#window' do

    it 'returns the window attribute' do
      window = double
      subject = described_class.new(:test, 1, window)
      expect(subject.window).to eq(window)
    end

  end

  describe '#==' do

    it 'returns true if the count and window are equal' do
      subject = described_class.new(:test, 1, double)
      expect(subject).to eq(subject.dup)
    end

    it 'returns false if the the name differs' do
      window = double
      subject1 = described_class.new(:test1, 1, window)
      subject2 = described_class.new(:test2, 1, window)
      expect(subject1).not_to eq(subject2)
    end

    it 'returns false if the the count differs' do
      window = double
      subject1 = described_class.new(:test, 1, window)
      subject2 = described_class.new(:test, 2, window)
      expect(subject1).not_to eq(subject2)
    end

    it 'returns false if the the window differs' do
      subject1 = described_class.new(:test, 1, double('window1'))
      subject2 = described_class.new(:test, 1, double('window2'))
      expect(subject1).not_to eq(subject2)
    end

  end

end
