require 'bundler/capistrano'

# Deploy to staging by default unless you specify '-S stage=production' on the command line
set :stage, 'staging' unless exists? :stage

configuration = YAML.load_file('config/general.yml')['deployment'][stage]

set :application, 'alaveteli'
set :scm, :git
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
end
