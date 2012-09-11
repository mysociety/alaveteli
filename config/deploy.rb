require 'bundler/capistrano'
require 'cape'

# Deploy to staging by default unless you specify '-S stage=production' on the command line
set :stage, 'staging' unless exists? :stage

configuration = YAML.load_file('config/deploy.yml')[stage]

set :application, 'alaveteli'
set :scm, :git
set :deploy_via, :remote_cache
set :repository, configuration['repository']
set :branch, configuration['branch']
set :git_enable_submodules, true
set :deploy_to, configuration['path']
set :user, configuration['user']
set :use_sudo, false

server configuration['server'], :app, :web, :db, :primary => true

namespace :rake do
  Cape do
    # Don't simply mirror all rake tasks because of a issue with Cape
    # https://github.com/njonsson/cape/issues/7
    mirror_rake_tasks 'themes:install' do |env|
      env['RAILS_ENV'] = rails_env
    end
  end
end

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc 'Link configuration after a code update'
  task :symlink_configuration do
    links = {
      "#{release_path}/config/database.yml" => "#{shared_path}/database.yml",
      "#{release_path}/config/general.yml"  => "#{shared_path}/general.yml"
    }

    # "ln -sf <a> <b>" creates a symbolic link but deletes <b> if it already exists
    run links.map {|a| "ln -sf #{a.last} #{a.first}"}.join(";")
  end
end

after 'deploy:update_code', 'deploy:symlink_configuration'
after 'deploy:update_code', 'rake:themes:install'
