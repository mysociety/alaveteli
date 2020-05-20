# == Schema Information
# Schema version: 20200520073810
#
# Table name: project_memberships
#
#  id         :integer          not null, primary key
#  project_id :integer
#  user_id    :integer
#  role_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

##
# A model to represent user membership to a project. Able to assign different
# roles for owners and contributors.
#
class Project::Membership < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :role

  validates :project, :user, :role, presence: true
end
