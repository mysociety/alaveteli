---
layout: page
title: Vagrant
---
# Alaveteli using Vagrant

<p class="lead">
Vagrant provides an easy method to set up virtual development environments; for
further information see <a href="http://www.vagrantup.com">the Vagrant website</a>.
We bundle an example Vagrantfile in the repository, which runs the
<a href="{{ site.baseurl }}docs/installing/script/">install script</a> for you.
</p>

Note that this is just one of [several ways to install Alaveteli]({{ site.baseurl }}docs/installing/).

The included steps will use vagrant to create a development environment
where you can run the test suite, the development server and make
changes to the codebase.

The basic process is to create a base virtual machine, and then
provision it with the software packages and setup needed. The supplied
scripts will create you a Vagrant VM based on the server edition of
Ubuntu 12.04 LTS that contains everything you need to work on Alaveteli.

1.   Get a copy of Alaveteli from GitHub and create the Vagrant instance.
  This will provision the system and can take some time - usually at
  least 20 minutes.

            # on your machine
            $ git clone git@github.com:mysociety/alaveteli.git
            $ cd alaveteli
            $ git submodule update --init
            $ vagrant --no-color up

2.   You should now be able to ssh in to the Vagrant guest OS and run the
  test suite:

            $ vagrant ssh

            # You are now in a terminal on the virtual machine
            $ cd /home/vagrant/alaveteli
            $ bundle exec rake spec


3.   Run the rails server and visit the application in your host browser
   at http://10.10.10.30:3000

            # in the virtual machine terminal
            bundle exec rails server


# Customizing the Vagrant instance

The Vagrantfile allows customisation of some aspects of the virtual machine. See the customization options in the file [`Vagrantfile`](https://github.com/mysociety/alaveteli/blob/master/Vagrantfile#L30) at the top level of the Alaveteli repository.

The options can be set either by prefixing the vagrant command, or by
exporting to the environment.

     # Prefixing the command
     $ ALAVETELI_VAGRANT_MEMORY=2048 vagrant up

     # Exporting to the environment
     $ export ALAVETELI_VAGRANT_MEMORY=2048
     $ vagrant up

Both have the same effect, but exporting will retain the variable for the duration of your shell session.

