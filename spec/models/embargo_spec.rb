# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: embargos
#
#  id              :integer          not null, primary key
#  info_request_id :integer          not null
#  publish_at      :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe Embargo, :type => :model do
  let(:embargo) { FactoryGirl.create(:embargo) }

  it 'belongs to an info_request' do
    expect(embargo.info_request).not_to be_nil
  end

  it 'has a publish_at field' do
    expect(embargo.publish_at).to be_a(ActiveSupport::TimeWithZone)
  end

end
