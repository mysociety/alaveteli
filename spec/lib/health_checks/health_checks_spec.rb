# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe HealthChecks do
  include HealthChecks

  describe '#add' do

    it 'adds a check to the collection and returns the check' do
      check = double('MockCheck', :ok? => true)
      expect(add(check)).to eq(check)
    end

    it 'does not add checks that do not define the check method' do
      check = double('BadCheck')
      expect(add(check)).to eq(false)
    end

  end

  describe '#all' do

    it 'returns all the checks' do
      check1 = double('MockCheck', :ok? => true)
      check2 = double('AnotherCheck', :ok? => false)
      add(check1)
      add(check2)
      expect(all).to include(check1, check2)
    end

  end

  describe '#each' do

    it 'iterates over each check' do
      expect(subject).to respond_to(:each)
    end

  end

  describe '#ok?' do

    it 'returns true if all checks are ok' do
      checks = [
        double('MockCheck', :ok? => true),
        double('FakeCheck', :ok? => true),
        double('TestCheck', :ok? => true)
      ]
      allow(HealthChecks).to receive_messages(:all => checks)

      expect(HealthChecks.ok?).to be true
    end

    it 'returns false if all checks fail' do
      checks = [
        double('MockCheck', :ok? => false),
        double('FakeCheck', :ok? => false),
        double('TestCheck', :ok? => false)
      ]
      allow(HealthChecks).to receive_messages(:all => checks)

      expect(HealthChecks.ok?).to be false
    end

    it 'returns false if a single check fails' do
      checks = [
        double('MockCheck', :ok? => true),
        double('FakeCheck', :ok? => false),
        double('TestCheck', :ok? => true)
      ]
      allow(HealthChecks).to receive_messages(:all => checks)

      expect(HealthChecks.ok?).to be false
    end

  end

end
