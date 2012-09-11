require 'bundler/capistrano'

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

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc "Link additional configuration after code update"
  after "deploy:update_code" do
    links = {
      "#{release_path}/config/database.yml" => "#{shared_path}/database.yml",
      "#{release_path}/config/general.yml"  => "#{shared_path}/general.yml"
    }

    # "ln -sf <a> <b>" creates a symbolic link but deletes <b> if it already exists
    run links.map {|a| "ln -sf #{a.last} #{a.first}"}.join(";")
  end
end
