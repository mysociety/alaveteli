# -*- encoding : utf-8 -*-
require 'rails/generators/active_record/migration'

class ActsAsXapianGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration
  source_root File.expand_path("../templates", __FILE__)
  def create_migration_file
    migration_template "migration.rb", "db/migrate/add_acts_as_xapian_jobs.rb"
  end
end
