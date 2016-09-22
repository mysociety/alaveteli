require 'rails/generators'

module AlaveteliPro
  class InstallGenerator < Rails::Generators::Base
    class_option :migrate, type: :boolean, default: true, banner: 'Run AlaveteliPro migrations'
    class_option :user_class, type: :string

    def self.source_paths
      paths = self.superclass.source_paths
      paths << File.expand_path('../templates', "../../#{__FILE__}")
      paths << File.expand_path('../templates', "../#{__FILE__}")
      paths << File.expand_path('../templates', __FILE__)
      paths.flatten
    end

    def prepare_options
      @run_migrations = options[:migrate]
    end

    def add_files
      template 'config/initializers/alaveteli_pro.rb.erb', 'config/initializers/alaveteli_pro.rb'
    end

    def install_migrations
      say_status :copying, "migrations"
      rake 'railties:install:migrations'
    end

    def run_migrations
      if @run_migrations
        say_status :running, "migrations"
        rake 'db:migrate'
      else
        say_status :skipping, "migrations (don't forget to run rake db:migrate)"
      end
    end

    def notify_about_routes
      insert_into_file File.join('config', 'routes.rb'), after: "Alaveteli::Application.routes.draw do\n" do
        %Q{
  # This line mounts AlaveteliPro's routes at the root of your application.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  mount AlaveteliPro::Engine, at: '/pro'
        }
      end

      puts "*" * 50
      puts "We added the following line to your application's config/routes.rb file:"
      puts " "
      puts "    mount AlaveteliPro::Engine, at: '/pro'"
    end

    def complete
      puts "*" * 50
      puts "Alaveteli has been installed successfully. You're all ready to go!"
      puts " "
      puts "Enjoy!"
    end
  end
end