# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe User::TransactionCalculator do

  let(:user) { FactoryGirl.create(:user) }

  subject { described_class.new(user) }

  describe '.new' do

    it 'requires a User' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'sets a list of default transaction associations' do
      list = described_class::DEFAULT_TRANSACTION_ASSOCIATIONS
      expect(described_class.new(user).transaction_associations).to eq(list)
    end

    it 'allows a list of custom transaction associations' do
      list = [:comments, :info_requests]
      calc = described_class.new(user, :transaction_associations => list)
      expect(calc.transaction_associations).to eq(list)
    end

    it 'raises an error if a transaction association is invalid' do
      list = [:invalid_method, :info_requests]
      expect {
        described_class.new(user, :transaction_associations => list)
      }.to raise_error(NoMethodError)
    end

  end

  describe '#user' do

    it 'returns the User' do
      expect(subject.user).to eq(user)
    end

  end

  describe '#total' do

    context 'with no arguments' do

      it 'sums the total transactions made by the user' do
        3.times do
          FactoryGirl.create(:comment, :user => user)
          FactoryGirl.create(:info_request, :user => user)
        end
        expect(subject.total).to eq(6)
      end

    end

    context 'with a Range argument' do

      it 'sums the total transactions made by the user during the range' do
        time_travel_to(1.year.ago) do
          FactoryGirl.create(:comment, :user => user)
          FactoryGirl.create(:info_request, :user => user)
        end

        time_travel_to(3.days.ago) do
          FactoryGirl.create(:comment, :user => user)
          FactoryGirl.create(:info_request, :user => user)
        end

        FactoryGirl.create(:comment, :user => user)

        expect(subject.total(10.days.ago..1.day.ago)).to eq(2)
      end

    end

    context 'with a Symbol argument' do

      it ':last_7_days sums the total transactions made by the user in the last 7 days' do
        time_travel_to(8.days.ago) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(7.days.ago) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(6.days.ago) do
          FactoryGirl.create(:comment, :user => user)
        end

        expect(subject.total(:last_7_days)).to eq(2)
      end

      it ':last_30_days sums the total transactions made by the user in the last 30 days' do
        time_travel_to(31.days.ago) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(30.days.ago) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(29.days.ago) do
          FactoryGirl.create(:comment, :user => user)
        end

        expect(subject.total(:last_30_days)).to eq(2)
      end

      it ':last_quarter sums the total transactions made by the user in the last quarter' do
        time_travel_to(Date.parse('2014-12-31')) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(Date.parse('2015-01-01')) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(Date.parse('2015-03-31')) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(Date.parse('2015-04-01')) do
          FactoryGirl.create(:comment, :user => user)
        end

        time_travel_to(Date.parse('2015-04-01')) do
          expect(subject.total(:last_quarter)).to eq(2)
        end
      end

      it 'raises an ArgumentError if the named range is invalid' do
        expect { subject.total(:invalid_range) }.
          to raise_error(ArgumentError, "Invalid range `:invalid_range'")
      end
    end

    it 'raises an ArgumentError if the argument is invalid' do
      expect { subject.total('invalid argument') }.
        to raise_error(ArgumentError, "Invalid argument `invalid argument'")
    end

  end

  describe '#total_per_month' do

    it 'returns a hash containing the total transactions grouped by month' do
      time_travel_to(Date.parse('2016-01-05')) do
        FactoryGirl.create(:comment, :user => user)
      end

      time_travel_to(Date.parse('2016-01-05')) do
        FactoryGirl.create(:info_request, :user => user)
      end

      time_travel_to(Date.parse('2016-01-05') + 1.hour) do
        FactoryGirl.create(:info_request, :user => user)
      end

      time_travel_to(Date.parse('2016-03-06')) do
        FactoryGirl.create(:comment, :user => user)
      end

      expect(subject.total_per_month).
        to eq({ '2016-01-01' => 3, '2016-03-01' => 1 })
    end

  end

end
