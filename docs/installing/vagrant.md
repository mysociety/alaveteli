---
layout: page
title: Vagrant
---
# Alaveteli using Vagrant

<p class="lead">
  <a href="https://www.vagrantup.com">Vagrant</a> provides an easy method to set
  up virtual development environments We bundle an example Vagrantfile in the
  repository, which runs the
  <a href="{{ site.baseurl}}docs/installing/script/">install script</a> for you.
</p>

Note that this is just one of [several ways to install Alaveteli]({{ site.baseurl }}docs/installing/).

The included steps will use vagrant to create a development environment
where you can run the test suite and the development server, and make
changes to the codebase.

The basic process is to create a base virtual machine (VM), and then
provision it with the software packages and setup needed. The supplied
scripts will create you a Vagrant VM based on the server edition of
Ubuntu 12.04 LTS that contains everything you need to work on Alaveteli.

1.  Get a copy of Alaveteli from
    <a href="{{ site.baseurl }}docs/glossary/#git" class="glossary__link">GitHub</a>:

            # on your machine
            $ git clone git@github.com:mysociety/alaveteli.git
            $ cd alaveteli
            $ git submodule update --init

2.  Create the Vagrant VM. This will provision the system and can take some time
    &mdash; sometimes as long as 20 minutes.

            $ vagrant --no-color up

3.  You should now be able to log in to the Vagrant guest OS with `ssh` and run
    the test suite:

            $ vagrant ssh

            # You are now in a terminal on the virtual machine
            $ cd /home/vagrant/alaveteli
            $ bundle exec rake spec


4.   Run the rails server:

            # in the virtual machine terminal
            bundle exec rails server

You can now visit the application in your browser (on the same machine that is
running Vagrant) at `http://10.10.10.30:3000`.

If you need to stop the server, simply press **Ctl-C** within that shell. 

It's also possible to stop the server from a different terminal shell in the
Vagrant VM. Log in, find the process ID for the Alaveteli server (in the example
below, this is `1234`), and issue the `kill` command:

            $ vagrant ssh

            # now in a terminal on the virtual machine
            $ cat /home/vagrant/alaveteli/tmp/pids/server.pid
            1234
            $ kill -2 1234

Alternatively, you can shut down the whole VM without deleting it with the
command <code>vagrant&nbsp;halt</code>
on the host command line. To start it up again, go to step 2, above &mdash; it
won't take so long this time, because the files are already in place.
See [the Vagrant documentation](https://docs.vagrantup.com/v2/)
for full instructions on using Vagrant.

## What next?

Check out the [next steps]({{ site.baseurl }}docs/installing/next_steps/).

## Customizing the Vagrant instance

The Vagrantfile allows customisation of some aspects of the virtual machine. See the customization options in the file [`Vagrantfile`](https://github.com/mysociety/alaveteli/blob/master/Vagrantfile#L30) at the top level of the Alaveteli repository.

The options can be set either by prefixing the vagrant command, or by
exporting to the environment.

     # Prefixing the command
     $ ALAVETELI_VAGRANT_MEMORY=2048 vagrant up

     # Exporting to the environment
     $ export ALAVETELI_VAGRANT_MEMORY=2048
     $ vagrant up

Both have the same effect, but exporting will retain the variable for the duration of your shell session.

