# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::WithTax do
  let(:plan) { OpenStruct.new(amount: 833) }
  subject { described_class.new(plan) }

  describe '#amount_with_tax' do

    it 'adds 20% tax to the plan amount' do
      expect(subject.amount_with_tax).to eq(1000)
    end

  end

  it 'delegates to the stripe plan' do
    expect(subject.amount).to eq(833)
  end

end
