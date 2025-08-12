# == Schema Information
# Schema version: 20210114161442
#
# Table name: project_memberships
#
#  id         :bigint           not null, primary key
#  project_id :bigint
#  user_id    :bigint
#  role_id    :bigint
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
