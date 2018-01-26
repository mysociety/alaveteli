# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: embargo_extensions
#
#  id                 :integer          not null, primary key
#  embargo_id         :integer
#  extension_duration :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'spec_helper'

RSpec.describe AlaveteliPro::EmbargoExtension do
  let(:embargo_extension) { FactoryGirl.create(:embargo_extension) }

  it "has an embargo" do
    expect(embargo_extension.embargo).to be_a AlaveteliPro::Embargo
  end

  it "has an extension_duration" do
    expect(embargo_extension.extension_duration).to be_a String
  end

  it "requires an embargo" do
    embargo_extension.embargo = nil
    expect(embargo_extension).not_to be_valid
  end

  it "requires an extension duration" do
    embargo_extension.extension_duration = nil
    expect(embargo_extension).not_to be_valid
  end

  it 'validates extension_duration field is in list' do
    embargo_extension.embargo.allowed_durations.each do |duration|
      embargo_extension.extension_duration = duration
      expect(embargo_extension).to be_valid
    end
    embargo_extension.extension_duration = "not_in_list"
    expect(embargo_extension).not_to be_valid
  end
end
