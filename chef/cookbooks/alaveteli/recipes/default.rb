require_recipe "openssl"
require_recipe "apt"


# Testing for platform:
# node[:lsb][:id] == "Debian"
# node[:lsb][:release] == "6.0"
# node[:lsb][:codename] == "squeeze"

if node.platform == "debian"
    path = "/var/lib/gems/1.8/bin"
else
    path = ""
end

apt_repository "mysociety" do
  uri "http://debian.mysociety.org"
  distribution "squeeze"
  components ["main"]
  action :add
end

# Install package dependencies as per the readme
packages = `cut -d " " -f 1 #{node[:root]}/config/packages | grep -v "^#"`.split
# mySociety packages are unauthenticated
mysociety_packages = %w{wkhtmltopdf-static pdftk}
packages.each do |pkg|
  package pkg do
    options "--allow-unauthenticated" if mysociety_packages.include? pkg
  end
end

include_recipe "postgresql::server"

# The database config
template "#{node[:root]}/config/database.yml" do
  source "database.yml.erb"
  mode "664"
  owner node[:user]
  group node[:group]
end

# Application config
cookbook_file "#{node[:root]}/config/general.yml" do
  source "general.yml"
  mode "644"
  owner node[:user]
  group node[:group]
end

# install dependencies

gem_package "bundler" do
    action :install
end

bash "bring bundle into the PATH" do
    code "ln -s #{path}/bundle /usr/local/bin/bundle"
    not_if "[ -e  /usr/local/bin/bundle ] || [ -e  /usr/bin/bundle ]"
end

bash "run bundle install" do
  user node[:user]
  cwd node[:root]
  environment ({'HOME' => '/home/vagrant'})
  code "bundle exec bundle install"
end

bash "bring rake into the PATH" do
    code "ln -s #{path}/rake /usr/local/bin/rake"
    not_if "[ -e  /usr/local/bin/rake ] || [ -e  /usr/bin/rake ]"
end

bash "create databases" do
  user node[:user]
  cwd node[:root]
  environment ({'HOME' => '/home/vagrant'})
  code "bundle exec rake db:create:all"
end

bash "checkout submodules" do
    user node[:user]
    cwd node[:root]
    code "git submodule update --init"
end

bash "run the post-install script" do
  cwd node[:root]
  user node[:user]
  environment ({'HOME' => '/home/vagrant'})
  code "bundle exec ./script/rails-post-deploy"
end
