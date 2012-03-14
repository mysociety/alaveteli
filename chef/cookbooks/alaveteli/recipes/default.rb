require_recipe "apt"
require 'json'
puts node[:lsb][:id]
puts node[:lsb][:release]
puts node[:lsb][:codename]

apt_repository "mysociety" do
  uri "http://debian.mysociety.org"
  distribution "squeeze"
  components ["main"]
  action :add
end

require_recipe "postgresql::server"

# Install package dependencies as per the readme
packages = `cut -d " " -f 1 #{node[:root]}/config/packages | grep -v "^#"`.split
# mySociety packages are unauthenticated
mysociety_packages = %w{wkhtmltopdf-static pdftk}
packages.each do |pkg|
  package pkg do
    options "--allow-unauthenticated" if mysociety_packages.include? pkg
  end
end

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
