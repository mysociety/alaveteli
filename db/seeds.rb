# -*- encoding : utf-8 -*-
# This file should contain all the record creation needed to seed the database
# with its default values.
#
# The data can then be loaded with the rails db:seed command (or created
# alongside the database with db:setup).
#
# Examples:
#
#   movies =
#     Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
# IMPORTANT! SEEDS MUST BE IDEMPOTENT. This generally means only creating seeds
# when they don't exist.
include AlaveteliFeatures::Helpers

Role.create(name: 'admin') if Role.where(name: 'admin').empty?

if feature_enabled?(:alaveteli_pro)
  %w[pro pro_admin].each do |role_name|
    Role.create(name: role_name) if Role.where(name: role_name).empty?
  end
end

if feature_enabled?(:projects)
  %w[project_owner project_contributor].each do |role_name|
    Role.create(name: role_name) if Role.where(name: role_name).empty?
  end
end

%w[
  draft complete clarification_needed awaiting_response
  response_received overdue very_overdue other embargo_expiring
].each do |category_slug|
  if AlaveteliPro::RequestSummaryCategory.where(slug: category_slug).empty?
    AlaveteliPro::RequestSummaryCategory.create(slug: category_slug)
  end
end
