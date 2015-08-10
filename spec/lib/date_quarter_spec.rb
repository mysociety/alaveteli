# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DateQuarter do
  include DateQuarter

  describe '#quarters_between' do

    it 'returns all the quarters in a year' do
      # This is a bit of a convoluted spec, since we have to convert each
      # Time in to an Integer to make a reasonable comparison
      # See http://makandracards.com/makandra/1057-why-two-ruby-time-objects-are-not-equal-although-they-appear-to-be
      with_env_tz 'UTC' do
        start = Time.parse('2014-01-01')
        finish = Time.parse('2014-12-31')

        expected = [['Wed Jan 01 00:00:00 +0000 2014', 'Mon Mar 31 23:59:59 +0000 2014'],
                    ['Tue Apr 01 00:00:00 +0000 2014', 'Mon Jun 30 23:59:59 +0000 2014'],
                    ['Tue Jul 01 00:00:00 +0000 2014', 'Tue Sep 30 23:59:59 +0000 2014'],
        ['Wed Oct 01 00:00:00 +0000 2014', 'Wed Dec 31 23:59:59 +0000 2014']].
          map { |pair| [Time.parse(pair[0]).to_i, Time.parse(pair[1]).to_i] }

        quarters_between(start, finish).each_with_index do |pair, i|
          pair.map!(&:to_i)
          expect(pair).to eq(expected[i])
        end
      end
    end

  end

end
