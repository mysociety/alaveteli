---
layout: page
title: Vagrant
---
# Installing Alaveteli using Vagrant

<p class="lead">
  <a href="https://www.vagrantup.com">Vagrant</a> provides an easy method to set
  up virtual development environments. We bundle an example Vagrantfile in the
  repository, which runs the
  <a href="{{ page.baseurl}}/docs/installing/script/">install script</a> for you.
</p>

Although this is just one of
[several ways to install Alaveteli]({{ page.baseurl }}/docs/installing/),
it's the best and easiest way to install it for
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">development</a>.

<div class="attention-box helpful-hint">
  Remember that you <em>must</em> customise Alaveteli before it’s ready for the
  public to use, so installing a development site is a necessary part of
  <a href="{{ page.baseurl }}/docs/installing/">installing Alaveteli</a>.
</div>

The included steps will use Vagrant to create a development environment
where you can run the test suite and the development server, make
changes to the codebase and — significantly for 
[customising Alaveteli]({{ page.baseurl }}/docs/customising/) —
create your own <a href="{{ page.baseurl }}/docs/glossary/#theme" class="glossary__link">theme</a>.

<div class="attention-box info">
  <p>
    <strong>What’s Vagrant?</strong>
    Vagrant is software that runs a simulation of another computer on your
    machine (or, more generally, any "host machine"). This is useful because
    although your machine might not be running Ubuntu, the simulation — called
    a <em>virtual machine</em> (VM) — can do. When you use Vagrant to install
    Alaveteli, it creates a VM that contains all the dependencies Alaveteli
    needs (which are defined in the <code>VagrantFile</code>). Because
    everything is in the VM, it doesn’t need to find or change anything on your
    own machine. This means you can work on any operating system that runs
    Vagrant, instead of needing to match what Alaveteli expects.
  </p>
  <p>
    You can edit the files just like any other files on your machine (because
    the folder is "shared" between your machine and the VM), and the VM uses
    port-forwarding so you can access its Alaveteli server through your browser.
  </p>
  <p>
    See
    <a href="https://docs.vagrantup.com/v2/">the Vagrant documentation</a>
    for more information.
  </p>
</div>

The basic process is to create a base virtual machine (VM), and then
provision it with the software packages and setup needed. The supplied
scripts will create you a Vagrant VM based on the server edition of
Ubuntu 12.04 LTS that contains everything you need to work on Alaveteli.

1.  Get a copy of Alaveteli from
    <a href="{{ page.baseurl }}/docs/glossary/#git" class="glossary__link">GitHub</a>:

            # on your machine
            $ git clone git@github.com:mysociety/alaveteli.git
            $ cd alaveteli
            $ git submodule update --init

2.  Create the Vagrant VM. This will provision the system and can take some time
    — sometimes as long as 20 minutes. Vagrant will download the files it
    needs, so the first time you do this, you must be online for this to work.

            $ vagrant --no-color up

    When the VM is ready, you'll see a message like `Machine booted and ready`,
    and control will be back at your command prompt.
    
3.  Once the machine is up, you can log in to it by doing <code>vagrant&nbsp;up</code>
    (from the same directory that contains the `VagrantFile`, so if you've
    just run `up` you're already in the right place). This will log you into
    the VM as the `vagrant` user. Immediately change to the `alaveteli`
    directory, because you need to be there when issuing any of the admin or
    rake tasks:

            $ vagrant ssh

            # You are now in a terminal on the virtual machine
            $ cd alaveteli

4. To start Alaveteli, run the rails server:

            # in the virtual machine terminal
            bundle exec rails server

You can now visit the application in your browser (on the same machine that is
running Vagrant) at `http://10.10.10.30:3000`.

### How to stop the server

You don't need to stop Alaveteli right away, but when you do here are
three ways:

* If you've still got a login in the Vagrant shell in which you ran the
  `rails server` command, simply press **Ctrl-C** to interrupt it.

* It's also possible to stop the server from a different terminal shell in the
  Vagrant VM. Log in, find the process ID for the Alaveteli server (in the
  example below, this is `1234`), and issue the `kill` command:

            $ vagrant ssh

            # now in a terminal on the virtual machine
            $ cat /home/vagrant/alaveteli/tmp/pids/server.pid
            1234
            $ kill -2 1234

* Alternatively, you can shut down the whole VM (without deleting it) with the
  command <code>vagrant&nbsp;halt</code> (from _outside_ Vagrant, that is, on
  the host machine's command line). To start it up again, go to step 2, above
  — it won't take so long this time, because the files are already in place.

## What next?

The Vagrant installation you've just done has loaded test data, which includes
an administrator account (`Joe Admin`). If you just want to dive straight into
customisation, every new Alaveteli site needs its own theme.

* follow the instruction to [create your own theme]({{ page.baseurl }}/docs/customising/make_a_new_theme/)

* if you've already done that, or want to stick with the default theme for now, see [other things you can do with a new installation]({{ page.baseurl }}/docs/installing/next_steps/).

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


