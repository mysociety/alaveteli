# -*- encoding : utf-8 -*-
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
include AlaveteliFeatures::Helpers

['admin', 'notifications_tester'].each do |role_name|
  if Role.where(:name => role_name).empty?
    Role.create(:name => role_name)
  end
end

if feature_enabled?(:alaveteli_pro)
  ['pro', 'pro_admin'].each do |role_name|
    if Role.where(:name => role_name).empty?
      Role.create(:name => role_name)
    end
  end
end

[
  'draft', 'complete', 'clarification_needed', 'awaiting_response',
  'response_received', 'overdue', 'very_overdue', 'other', 'embargo_expiring'
].each do |category_slug|
  if AlaveteliPro::RequestSummaryCategory.where(:slug => category_slug).empty?
    AlaveteliPro::RequestSummaryCategory.create(:slug => category_slug)
  end
end
