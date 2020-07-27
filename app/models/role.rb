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

class Role < ApplicationRecord
  extend AlaveteliFeatures::Helpers

  has_and_belongs_to_many :users,
                          join_table: :users_roles,
                          inverse_of: :roles

  belongs_to :resource,
             polymorphic: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify

  ROLES = %w[admin].freeze
  PRO_ROLES = %w[pro pro_admin].freeze
  PROJECT_ROLES = %w[project_owner project_contributor].freeze

  def self.allowed_roles
    [].tap do |allowed|
      allowed.push(*ROLES)
      allowed.push(*PRO_ROLES) if feature_enabled? :alaveteli_pro
      allowed.push(*PROJECT_ROLES) if feature_enabled? :projects
    end
  end

  validates :name,
            inclusion: { in: -> (_name) { Role.allowed_roles } },
            uniqueness: { scope: :resource_type }

  def self.admin_role
    Role.find_by(name: 'admin')
  end

  def self.pro_role
    Role.find_by(name: 'pro')
  end

  def self.project_owner_role
    Role.find_by(name: 'project_owner')
  end

  def self.project_contributor_role
    Role.find_by(name: 'project_contributor')
  end

  # Public: Returns an array of symbols of the names of the roles
  # which can be granted or revoked
  #
  # Returns an Array
  def self.grantable_roles
    allowed_roles.flat_map do |role|
      grants_and_revokes(role.to_sym)
    end.compact.uniq
  end

  # Public: Returns an array of symbols of the names of the roles
  # this role can grant and revoke
  #
  # role - the name of the role as a symbol
  #
  # Returns an Array
  def self.grants_and_revokes(role)
    grants_and_revokes = {
      admin: [:admin],
      pro_admin: [:pro, :admin, :pro_admin]
    }
    grants_and_revokes[role] || []
  end

  # Public: Returns an array of symbols of the names of the roles
  # this role requires
  #
  # role - the name of the role as a symbol
  #
  # Returns an Array
  def self.requires(role)
    { pro_admin: [:admin] }[role] || []
  end
end
