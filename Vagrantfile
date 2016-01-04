# Welcome! Thanks for taking an interest in contributing to Alaveteli.
# This Vagrantfile should get you started with the minimum of fuss.
#
# Usage
# =====
#
# Get a copy of Alaveteli from GitHub and create the Vagrant instance
#
#   # Host
#   $ git clone git@github.com:mysociety/alaveteli.git
#   $ cd alaveteli
#   $ git submodule update --init
#   $ vagrant --no-color up
#
# You should now be able to ssh in to the guest and run the test suite
#
#   # Host
#   $ vagrant ssh
#
#   # Guest
#   $ cd /home/vagrant/alaveteli
#   $ bundle exec rake spec
#
# Run the rails server and visit the application in your host browser
# at http://10.10.10.30:3000
#
#   # Guest
#   bundle exec rails server
#
# Customizing the Vagrant instance
# ================================
#
# This Vagrantfile allows customisation of some aspects of the virtaual machine
# See the customization options below for details.
#
# The options can be set either by prefixing the vagrant command, or by
# exporting to the environment.
#
#   # Prefixing the command
#   $ ALAVETELI_VAGRANT_MEMORY=2048 vagrant up
#
#   # Exporting to the environment
#   $ export ALAVETELI_VAGRANT_MEMORY=2048
#   $ vagrant up
#
# Both have the same effect, but exporting will retain the variable for the
# duration of your shell session.
#
# Using Themes
# ------------
#
# You can also use the built in theme switcher (script/switch-theme.rb). The
# ALAVETELI_THEMES_DIR will be shared in to /home/vagrant/alaveteli-themes so
# that the default location is used on the guest. You can use the env var
# ALAVETELI_THEMES_DIR to change where this Vagrantfile looks for the themes
# directory on the host.
#
# Customization Options
# =====================
ALAVETELI_FQDN = ENV['ALAVETELI_VAGRANT_FQDN'] || "alaveteli.10.10.10.30.xip.io"
ALAVETELI_MEMORY = ENV['ALAVETELI_VAGRANT_MEMORY'] || 1536
ALAVETELI_THEMES_DIR = ENV['ALAVETELI_THEMES_DIR'] || '../alaveteli-themes'
ALAVETELI_OS = ENV['ALAVETELI_VAGRANT_OS'] || 'precise64'

SUPPORTED_OPERATING_SYSTEMS = {
  'precise64' => 'https://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box',
  'wheezy64' => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-73-x64-virtualbox-nocm.box'
}

def box
  ALAVETELI_OS
end

def box_url
  SUPPORTED_OPERATING_SYSTEMS[ALAVETELI_OS]
end

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = box
  config.vm.box_url = box_url
  config.vm.network :private_network, :ip => "10.10.10.30"

  config.vm.synced_folder ".", "/home/vagrant/alaveteli", :owner => "vagrant", :group => "vagrant"

  if File.directory?(ALAVETELI_THEMES_DIR)
    config.vm.synced_folder ALAVETELI_THEMES_DIR,
                            "/home/vagrant/alaveteli-themes",
                            :owner => "vagrant",
                            :group => "vagrant"
  end

  config.ssh.forward_agent = true

  # The bundle install fails unless you have quite a large amount of
  # memory; insist on 1.5GiB:
  config.vm.provider "virtualbox" do |vb|
    host = RbConfig::CONFIG['host_os']
    # Give VM access to all cpu cores on the host
    if host =~ /darwin/
      cpus = `sysctl -n hw.ncpu`.to_i
    elsif host =~ /linux/
      cpus = `nproc`.to_i
    else # sorry Windows folks, I can't help you
      cpus = 1
    end

    vb.customize ["modifyvm", :id, "--memory", ALAVETELI_MEMORY]
    vb.customize ["modifyvm", :id, "--cpus", cpus]
  end

  # Fetch and run the install script:
  config.vm.provision :shell, :inline => "apt-get -y install curl"
  config.vm.provision :shell, :inline => "curl -O https://raw.githubusercontent.com/mysociety/commonlib/master/bin/install-site.sh"
  config.vm.provision :shell, :inline => "chmod a+rx install-site.sh"
  config.vm.provision :shell, :inline => "./install-site.sh " \
                                             "--dev " \
                                             "alaveteli " \
                                             "vagrant " \
                                             "#{ ALAVETELI_FQDN }"

  # Append basic usage instructions to the MOTD
  motd = <<-EOF
To start your alaveteli instance:
* cd alaveteli
* bundle exec rails server
EOF

  config.vm.provision :shell, :inline => "echo '#{ motd }' >> /etc/motd.tail"
end
