require_recipe "apt"
require_recipe "postgresql::server"


# Install package dependencies as per the readme
packages = `cut -d " " -f 1 /vagrant/config/packages | grep -v "^#"`.split
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# The database config
template "/vagrant/config/database.yml" do
  source "database.yml.erb"
  mode "664"
  owner "vagrant"
  group "vagrant"
end
