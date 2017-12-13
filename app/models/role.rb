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

class Role < ActiveRecord::Base
  extend AlaveteliFeatures::Helpers

  has_and_belongs_to_many :users,
                          :join_table => :users_roles,
                          :inverse_of => :roles

  belongs_to :resource,
             :polymorphic => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify


  ROLES = ['admin'].freeze
  PRO_ROLES = ['pro', 'pro_admin'].freeze

  def self.allowed_roles
    if feature_enabled? :alaveteli_pro
      ROLES + PRO_ROLES
    else
      ROLES
    end
  end

  validates :name,
            :inclusion => { :in => lambda { |role| Role.allowed_roles } },
            :uniqueness => { :scope => :resource_type }

  def self.admin_role
    Role.find_by(name: 'admin')
  end

  def self.pro_role
    Role.find_by(name: 'pro')
  end

  # Public: Returns an array of symbols of the names of the roles
  # this role can grant and revoke
  #
  # role - the name of the role as a symbol
  #
  # Returns an Array
  def self.grants_and_revokes(role)
    grants_and_revokes = {
      :admin => [:admin],
      :pro_admin => [:pro, :admin, :pro_admin]
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
    { :pro_admin => [:admin] }[role] || []
  end

end
