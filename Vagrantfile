require 'pp'
require 'yaml'
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
#   bundle exec rails server -b 0.0.0.0
#
# Customizing the Vagrant instance
# ================================
#
# This Vagrantfile allows customisation of some aspects of the virtaual machine
# See the customization options below for details.
#
# The options can be set either by prefixing the vagrant command, using
# `.vagrant.yml`, or by exporting to the environment.
#
#   # Prefixing the command
#   $ ALAVETELI_VAGRANT_MEMORY=2048 vagrant up
#
#   # .vagrant.yml
#   $ echo "memory: 2048" >> .vagrant.yml
#   $ vagrant up
#
#   # Exporting to the environment
#   $ export ALAVETELI_VAGRANT_MEMORY=2048
#   $ vagrant up
#
# All have the same effect, but exporting will retain the variable for the
# duration of your shell session, whereas `.vagrant.yml` will be persistent.
# The environment takes precedence over `.vagrant.yml`.
#
# Using Themes
# ------------
#
# You can also use the built in theme switcher (script/switch-theme.rb). The
# ALAVETELI_THEMES_DIR will be shared in to /home/vagrant/alaveteli-themes so
# that the default location is used on the guest. You can use the env var
# ALAVETELI_THEMES_DIR to change where this Vagrantfile looks for the themes
# directory on the host.

def cpu_count
  host = RbConfig::CONFIG['host_os']
  # Give VM access to all cpu cores on the host
  if host =~ /darwin/
    `sysctl -n hw.ncpu`.to_i
  elsif host =~ /linux/
    `nproc`.to_i
  else # sorry Windows folks, I can't help you
    1
  end
end

# Customization Options
# =====================
#
# Defaults can be overridden either in `.vagrant.yml` with the same key name, or
# via the environment by prefixing the key with `ALAVETELI_VAGRANT_` and
# upcasing. Boolean values can be set to `false` in the environment with "0",
# "false" or "no".
DEFAULTS = {
  'fqdn' => 'alaveteli.10.10.10.30.nip.io',
  'ip' => '10.10.10.30',
  'memory' => 1536,
  'themes_dir' => '../alaveteli-themes',
  'os' => 'jessie64',
  'name' => 'default',
  'use_nfs' => false,
  'show_settings' => false,
  'cpus' => cpu_count
}.freeze

env = DEFAULTS.keys.reduce({}) do |memo, key|
  value = ENV["ALAVETELI_VAGRANT_#{ key.upcase }"]
  value = false if %w(0 false no).include?(value)
  memo[key] = value unless value.nil?
  memo
end

settings_file_path = File.dirname(__FILE__) + '/.vagrant.yml'
settings_file = if File.exist?(settings_file_path)
  YAML.load(File.read(settings_file_path))
else
  {}
end

SETTINGS = DEFAULTS.merge(settings_file).merge(env).freeze

if SETTINGS['show_settings']
  puts 'Current machine settings:'
  puts "\n"
  pp SETTINGS
  puts "\n"
end

SUPPORTED_OPERATING_SYSTEMS = {
  'trusty64' => 'https://app.vagrantup.com/ubuntu/boxes/trusty64',
  'jessie64' => 'https://app.vagrantup.com/puppetlabs/debian-8.2-64-nocm',
  'stretch64' => 'https://app.vagrantup.com/debian/boxes/stretch64',
  'xenial64' => 'https://app.vagrantup.com/ubuntu/boxes/xenial64'
}

def box
  SETTINGS['os']
end

def box_url
  SUPPORTED_OPERATING_SYSTEMS[box]
end

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = if box == 'jessie64'
    'puppetlabs/debian-8.2-64-nocm'
  elsif box == 'stretch64'
    'debian/stretch64'
  elsif box == 'trusty64'
    'ubuntu/trusty64'
  elsif box == 'xenial64'
    'ubuntu/xenial64'
  else
    box
  end
  config.vm.define SETTINGS['name']
  config.vm.box_url = box_url
  config.vm.network :private_network, ip: SETTINGS['ip']

  config.vm.synced_folder '.', '/vagrant', disabled: true

  if SETTINGS['use_nfs']
    config.vm.synced_folder '.', '/home/vagrant/alaveteli', nfs: true
  else
    config.vm.synced_folder '.',
                            '/home/vagrant/alaveteli',
                            owner: 'vagrant',
                            group: 'vagrant'
  end

  if File.directory?(SETTINGS['themes_dir'])
    if SETTINGS['use_nfs']
      config.vm.synced_folder SETTINGS['themes_dir'],
                              '/home/vagrant/alaveteli-themes',
                              nfs: true
    else
      config.vm.synced_folder SETTINGS['themes_dir'],
                              '/home/vagrant/alaveteli-themes',
                              owner: 'vagrant',
                              group: 'vagrant'
    end
  end

  config.ssh.forward_agent = true

  # The bundle install fails unless you have quite a large amount of
  # memory; insist on 1.5GiB:
  config.vm.provider 'virtualbox' do |vb|
    vb.customize ['modifyvm', :id, '--memory', SETTINGS['memory']]
    vb.customize ['modifyvm', :id, '--cpus', SETTINGS['cpus']]
  end

  config.vm.provision :shell, inline: <<-EOF
  if [[ -f "/home/vagrant/alaveteli/commonlib/bin/install-site.sh" ]]
    then
      /home/vagrant/alaveteli/commonlib/bin/install-site.sh \
        --dev \
        alaveteli \
        vagrant \
        #{ SETTINGS['fqdn'] }
  else
    echo "Couldn't find provisioning script." >&2
    echo "Did you forget to run git submodule update --init?" >&2
    exit 1
  fi
EOF

  # Append basic usage instructions to the MOTD
  motd = <<-EOF
To start your alaveteli instance:
* cd alaveteli
* bundle exec rails server -b 0.0.0.0
EOF

  if SETTINGS['os'] == 'jessie64'
    # workaround for dynamic MOTD support on jessie
    # adapted from: https://oitibs.com/debian-jessie-dynamic-motd/
    config.vm.provision :shell, inline: "mkdir /etc/update-motd.d/"
    config.vm.provision :shell, inline: "cd /etc/update-motd.d/ && touch 00-header && touch 10-sysinfo && touch 90-footer"
    config.vm.provision :shell, inline: "echo '#!/bin/sh' >> /etc/update-motd.d/90-footer"
    config.vm.provision :shell, inline: "echo '[ -f /etc/motd.tail ] && cat /etc/motd.tail || true' >> /etc/update-motd.d/90-footer"
    config.vm.provision :shell, inline: "chmod +x /etc/update-motd.d/*"
    config.vm.provision :shell, inline: "rm /etc/motd"
    config.vm.provision :shell, inline: "ln -s /var/run/motd /etc/motd"
  elsif SETTINGS['os'] == 'trusty64' || SETTINGS['os'] == 'xenial64'
    config.vm.provision :shell, inline: "echo '#{ motd }' >> /etc/motd"
  end
  config.vm.provision :shell, inline: "echo '#{ motd }' >> /etc/motd.tail"

  # Display next steps info at the end of a successful install
  instructions = <<-EOF

Welcome to your new Alaveteli development site!

If you are planning to use a custom theme, you should create
an `alaveteli-themes` folder at the same level as your `alaveteli`
code folder to hold your theme repositories so that your
Vagrant box will see your theme folders when using the
switch-theme.rb script (take a look at the documentation in
the script/switch-theme.rb file for more information).

Full instructions for customising your install can be found online:
http://alaveteli.org/docs/customising/

Type `vagrant ssh` to log into the Vagrant box to start the site
or run the test suite
EOF

  config.vm.provision :shell, inline: "echo '#{ instructions }'"
end
