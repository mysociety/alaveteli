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
    with_feature_enabled(:alaveteli_pro) do
      role = Role.new(:name => 'pro')
      role.valid?
      expect(role.errors[:name]).to eq(["has already been taken"])
    end
  end

  describe '.grants_and_revokes' do

    it 'returns an array [:admin, :notifications_tester] when passed :admin' do
      expect(Role.grants_and_revokes(:admin))
        .to eq([:admin, :notifications_tester])
    end

    it 'returns an array [:pro, :admin, :pro_admin, :notifications_tester]
        when passed :pro_admin' do
      expect(Role.grants_and_revokes(:pro_admin))
        .to eq([:pro, :admin, :pro_admin, :notifications_tester])
    end

    it 'returns an empty array when passed :pro' do
      expect(Role.grants_and_revokes(:pro)).to eq([])
    end

    it 'returns an empty array when passed :notifications_tester' do
      expect(Role.grants_and_revokes(:notifications_tester)).to eq([])
    end

  end

  describe '.requires' do

    it 'returns an empty array when passed :admin' do
      expect(Role.requires(:admin)).to eq([])
    end

    it 'returns an array [:admin] when passed :pro_admin' do
      expect(Role.requires(:pro_admin)).to eq([:admin])
    end

    it 'returns an empty array when passed :pro' do
      expect(Role.requires(:pro)).to eq([])
    end

    it 'returns an empty array when passed :notifications_tester' do
      expect(Role.requires(:notifications_tester)).to eq([])
    end

  end

end
