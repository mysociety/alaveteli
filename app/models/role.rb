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
  has_and_belongs_to_many :users, :join_table => :users_roles

  belongs_to :resource,
             :polymorphic => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify

  validates :name,
            :inclusion => { :in => lambda { |role| role.allowed_roles } },
            :uniqueness => { :scope => :resource_type }

  ALLOWED_ROLES = ['admin', 'pro'].freeze

  def allowed_roles
    ALLOWED_ROLES
  end

  def self.admin_role
    Role.where(:name => 'admin').first
  end

  def self.grants_and_revokes(role)
    { :admin => [:admin] }[role]
  end

end
