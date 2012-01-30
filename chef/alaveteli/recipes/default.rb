require_recipe "apt"

apt_repository "mysociety" do
  uri "http://debian.mysociety.org"
  distribution "squeeze"
  components ["main"]
  action :add
end

require_recipe "postgresql::server"

# Install package dependencies as per the readme
packages = `cut -d " " -f 1 /vagrant/config/packages | grep -v "^#"`.split
packages.each do |pkg|
  package pkg do
    options "--allow-unauthenticated" if pkg == "wkhtmltopdf-static"
  end
end

# The database config
template "/vagrant/config/database.yml" do
  source "database.yml.erb"
  mode "664"
  owner "vagrant"
  group "vagrant"
end
