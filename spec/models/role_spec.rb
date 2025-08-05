# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: roles
#
#  id            :integer          not null, primary key
#  name          :string
#  resource_id   :integer
#  resource_type :string
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

  describe '.admin_role' do

    it 'returns role with name admin' do
      expect(Role.admin_role.name).to eq 'admin'
    end

  end

  describe '.pro_role' do

    it 'returns role with name pro' do
      expect(Role.pro_role.name).to eq 'pro'
    end

  end

  describe '.grantable_roles' do

    context 'when alaveteli_pro feature is disabled' do

      it 'returns an array [:admin]' do
        expect(Role.grantable_roles).to match_array %i[admin]
      end

    end

    context 'when alaveteli_pro feature is enabled', feature: :alaveteli_pro do

      it 'returns an array [:admin, :pro, :pro_admin]' do
        expect(Role.grantable_roles).to match_array %i[pro admin pro_admin]
      end

    end

  end

  describe '.grants_and_revokes' do

    it 'returns an array [:admin] when passed :admin' do
      expect(Role.grants_and_revokes(:admin))
        .to eq([:admin])
    end

    it 'returns an array [:pro, :admin, :pro_admin]
        when passed :pro_admin' do
      expect(Role.grants_and_revokes(:pro_admin))
        .to eq([:pro, :admin, :pro_admin])
    end

    it 'returns an empty array when passed :pro' do
      expect(Role.grants_and_revokes(:pro)).to eq([])
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

  end

end
