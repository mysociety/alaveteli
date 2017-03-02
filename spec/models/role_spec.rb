# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: roles
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  resource_id   :integer
#  resource_type :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe Role do

  it 'validates the role name is in the allowed roles' do
    role = Role.new(:name => 'test')
    role.valid?
    expect(role.errors[:name]).to eq(["is not included in the list"])
  end

  it 'validates the role is unique within the context of a resource_type' do
    role = Role.new(:name => 'pro')
    role.valid?
    expect(role.errors[:name]).to eq(["has already been taken"])
  end

  describe '.grants_and_revokes' do

    it 'returns an array [:admin] when passed :admin' do
      expect(Role.grants_and_revokes(:admin))
        .to eq([:admin])
    end

  end

end
