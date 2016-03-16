# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorldFOIWebsites do

  describe '.can_ask_the_eu?' do

    it 'is false if the current site is AskTheEU' do
      allow(AlaveteliConfiguration).
        to receive(:domain).and_return('www.asktheeu.org')
      expect(described_class.can_ask_the_eu?('ES')).to eq(false)
    end

    it 'is false if the current user is not in an EU country' do
      expect(described_class.can_ask_the_eu?('US')).to eq(false)
    end

    it 'is true if the current user is in an EU country' do
      expect(described_class.can_ask_the_eu?('ES')).to eq(true)
    end

  end

end
