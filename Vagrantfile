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
# Customization Options
# =====================
ALAVETELI_FQDN = ENV['ALAVETELI_VAGRANT_FQDN'] || "alaveteli.10.10.10.30.xip.io"
ALAVETELI_MEMORY = ENV['ALAVETELI_VAGRANT_MEMORY'] || 1536
ALAVETELI_THEMES_DIR = ENV['ALAVETELI_THEMES_DIR'] || '../alaveteli-themes'

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
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
    vb.customize ["modifyvm", :id, "--memory", ALAVETELI_MEMORY]
  end

  # Fetch and run the install script:
  config.vm.provision :shell, :inline => "wget -O install-site.sh https://raw.github.com/mysociety/commonlib/master/bin/install-site.sh"
  config.vm.provision :shell, :inline => "chmod a+rx install-site.sh"
  config.vm.provision :shell, :inline => "./install-site.sh " \
                                             "--dev " \
                                             "alaveteli " \
                                             "vagrant " \
                                             "#{ ALAVETELI_FQDN }"
end
