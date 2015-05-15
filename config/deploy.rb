# -*- encoding : utf-8 -*-
require 'bundler/capistrano'

set :stage, 'staging' unless exists? :stage

configuration = YAML.load_file('config/deploy.yml')[stage]

set :application, 'alaveteli'
set :scm, :git
set :deploy_via, :remote_cache
set :repository, configuration['repository']
set :branch, configuration['branch']
set :git_enable_submodules, true
set :deploy_to, configuration['deploy_to']
set :user, configuration['user']
set :use_sudo, false
set :rails_env, configuration['rails_env']
set :daemon_name, configuration.fetch('daemon_name', 'alaveteli')

server configuration['server'], :app, :web, :db, :primary => true

namespace :themes do
  task :install do
    run "cd #{latest_release} && bundle exec rake themes:install RAILS_ENV=#{rails_env}"
  end
end


# Not in the rake namespace because we're also specifying app-specific arguments here
namespace :xapian do
  desc 'Rebuilds the Xapian index as per the ./scripts/rebuild-xapian-index script'
  task :rebuild_index do
    run "cd #{current_path} && bundle exec rake xapian:rebuild_index models='PublicBody User InfoRequestEvent' RAILS_ENV=#{rails_env}"
  end
end

namespace :deploy do

  [:start, :stop, :restart].each do |t|
    desc "#{t.to_s.capitalize} Alaveteli service defined in /etc/init.d/"
    task t, :roles => :app, :except => { :no_release => true } do
      run "service #{ daemon_name } #{ t }"
    end
  end

  desc 'Link configuration after a code update'
  task :symlink_configuration do
    links = {
      "#{release_path}/config/database.yml" => "#{shared_path}/database.yml",
      "#{release_path}/config/general.yml" => "#{shared_path}/general.yml",
      "#{release_path}/config/rails_env.rb" => "#{shared_path}/rails_env.rb",
      "#{release_path}/config/newrelic.yml" => "#{shared_path}/newrelic.yml",
      "#{release_path}/config/httpd.conf" => "#{shared_path}/httpd.conf",
      "#{release_path}/config/aliases" => "#{shared_path}/aliases",
      "#{release_path}/public/foi-live-creation.png" => "#{shared_path}/foi-live-creation.png",
      "#{release_path}/public/foi-user-use.png" => "#{shared_path}/foi-user-use.png",
      "#{release_path}/files" => "#{shared_path}/files",
      "#{release_path}/cache" => "#{shared_path}/cache",
      "#{release_path}/log" => "#{shared_path}/log",
      "#{release_path}/tmp/pids" => "#{shared_path}/tmp/pids",
      "#{release_path}/lib/acts_as_xapian/xapiandbs" => "#{shared_path}/xapiandbs",
      "#{release_path}/lib/themes" => "#{shared_path}/themes",
    }

    # "ln -sf <a> <b>" creates a symbolic link but deletes <b> if it already exists
    run links.map {|a| "ln -sf #{a.last} #{a.first}"}.join(";")
  end

  after 'deploy:setup' do
    run "mkdir -p #{shared_path}/files"
    run "mkdir -p #{shared_path}/cache"
    run "mkdir -p #{shared_path}/log"
    run "mkdir -p #{shared_path}/tmp/pids"
    run "mkdir -p #{shared_path}/xapiandbs"
    run "mkdir -p #{shared_path}/themes"
  end
end

before 'deploy:assets:precompile', 'deploy:symlink_configuration'
before 'deploy:assets:precompile', 'themes:install'

# Put up a maintenance notice if doing a migration which could take a while
before 'deploy:migrate', 'deploy:web:disable'
after 'deploy:migrate', 'deploy:web:enable'

