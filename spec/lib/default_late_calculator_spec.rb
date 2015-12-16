# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DefaultLateCalculator do

  describe '.description' do

    it 'returns the human description' do
      desc = %q(Defaults controlled by config/general.yml)
      expect(described_class.description).to eq(desc)
    end

  end

  describe '#reply_late_after_days' do

    it 'returns the value set in config/general.yml' do
      allow(AlaveteliConfiguration).
        to receive(:reply_late_after_days).and_return(7)
      expect(subject.reply_late_after_days).to eq(7)
    end

  end

  describe '#reply_very_late_after_days' do

    it 'returns the value set in config/general.yml' do
      allow(AlaveteliConfiguration).
        to receive(:reply_very_late_after_days).and_return(7)
      expect(subject.reply_very_late_after_days).to eq(7)
    end

  end

end
