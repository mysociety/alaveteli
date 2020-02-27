require 'rails/generators'

module AlaveteliFeatures
  class InstallGenerator < Rails::Generators::Base
    class_option :migrate, type: :boolean, default: true, banner: 'Run AlaveteliFeatures migrations'

    def self.source_paths
      paths = superclass.source_paths
      paths << File.expand_path('../templates', "../../#{__FILE__}")
      paths << File.expand_path('../templates', "../#{__FILE__}")
      paths << File.expand_path('../templates', __FILE__)
      paths.flatten
    end

    def prepare_options
      @run_migrations = options[:migrate]
    end

    def install_migrations
      say_status :copying, "migrations"
      generate 'flipper:active_record'
    end

    def run_migrations
      if @run_migrations
        say_status :running, "migrations"
        rake 'db:migrate'
      else
        say_status :skipping, "migrations (don't forget to run rake db:migrate)"
      end
    end

    def add_files
      template 'config/initializers/alaveteli_features.rb.erb', 'config/initializers/alaveteli_features.rb'
    end

    def complete
      puts "*" * 50
      puts "AlaveteliFeatures has been installed successfully. You're all ready to go!"
      puts " "
      puts "Enjoy!"
    end
  end
end
