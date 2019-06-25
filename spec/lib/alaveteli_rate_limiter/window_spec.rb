# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliRateLimiter::Window do

  describe '.from_hash' do

    it 'creates a Window from a Hash' do
      expected = described_class.new(3, :day)
      hash = { :value => 3, :unit => :day }
      expect(described_class.from_hash(hash)).to eq(expected)
    end

    it 'requires a :value key' do
      hash = { :unit => :day }
      expect { described_class.from_hash(hash) }.to raise_error(KeyError)
    end

    it 'requires a :unit key' do
      hash = { :value => 3 }
      expect { described_class.from_hash(hash) }.to raise_error(KeyError)
    end

  end

  describe '.new' do

    it 'requires a value' do
      expect { described_class.new(:hour) }.to raise_error(ArgumentError)
    end

    it 'requires a numeric value' do
      expect { described_class.new('hi', :hour) }.to raise_error(ArgumentError)
    end

    it 'converts a numeric value to an Integer' do
      expect(described_class.new('1', :hour).value).to eq(1)
    end

    it 'requires a unit' do
      expect { described_class.new(1) }.to raise_error(ArgumentError)
    end

    it 'requires a valid unit ' do
      msg = "Invalid unit :tomato - " \
            "must be one of #{ described_class::VALID_UNITS }"
      expect { described_class.new(1, :tomato) }.
        to raise_error(ArgumentError, msg)
    end

  end

  describe '#include?' do

    it 'returns true if an event is inside the window' do
      time_travel_to(Time.zone.parse('2016-10-21')) do
        subject = described_class.new(1, :day)
        expect(subject.include?(10.minutes.ago)).to eq(true)
      end
    end

    it 'returns false if the event is not inside the window' do
      time_travel_to(Time.zone.parse('2016-10-21')) do
        subject = described_class.new(1, :day)
        expect(subject.include?(2.days.ago)).to eq(false)
      end
    end

  end

  describe '#cutoff' do

    it 'calculates the end of the window based on the attributes' do
      time = Time.zone.parse('2016-10-21')
      time_travel_to(time) do
        subject = described_class.new(1, :hour)
        expect(subject.cutoff).to be_within(1.second).of(time - 1.hour)
      end
    end

  end

  describe '#==' do

    it 'returns true if the value and unit are equal' do
      subject = described_class.new(1, :hour)
      expect(subject).to eq(subject.dup)
    end

    it 'returns false if the the value differs' do
      rule = double
      subject1 = described_class.new(1, :hour)
      subject2 = described_class.new(2, :hour)
      expect(subject1).not_to eq(subject2)
    end

    it 'returns false if the the unit differs' do
      subject1 = described_class.new(1, :hour)
      subject2 = described_class.new(1, :minute)
      expect(subject1).not_to eq(subject2)
    end

  end

end
