---
layout: page
title: Cron jobs and Daemons
---

# Cron jobs and Daemons

<p class="lead">
  Alaveteli runs some processes as operating system daemons. This guide explains
  how to generate the daemon files and get them running.
</p>

From Alaveteli version `0.39` the crontab and init scripts use the `erb` file
format, which is a standard templating format used by many Ruby applications.

Previously scripts use the `ugly` file format, which is a strange templating
format used by mySociety.

The `ugly` format uses simple variable substitution. A variable looks like
`!!(*= $this *)!!`.

## Generate crontab

`config/crontab-example` contains the cron jobs that run on
Alaveteli. Rewrite the example file to replace the variables,
and then drop it in `/etc/cron.d/` on the server.

**Template Variables:**

* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `user`: the user that the software runs as
* `site`: a string to identify your Alaveteli instance
* `mailto`: The email address or local account that cron output will be sent to - setting an email address depends on your MTA having been configured for remote delivery.
* `ruby_version`: The version of ruby that was used to install `bundler` as a gem,
  if that was neccessary. This will be used to add the deployment user's local
  gem directory to the `PATH` used in the cron file

There is a rake task that will help to rewrite this file into one that is
useful to you. This example sends cron output to the local `alaveteli` user. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_crontab \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      MAILTO=alaveteli \
      CRONTAB=/var/www/alaveteli/config/crontab-example > /etc/cron.d/alaveteli
    popd

    chown root:alaveteli /etc/cron.d/alaveteli
    chmod 754 /etc/cron.d/alaveteli

Note: If you are generating the crontab manually, rather than with this rake task,
you will need to add a line to periodically check on each daemon you install following
the instructions below, as follows, making sure to replace DAEMON_NAME with the name
of the daemon file:

    5,15,25,35,45,55 * * * * alaveteli /etc/init.d/DAEMON_NAME check

## Generate application daemon

Generate a daemon based on the application server you installed. This allows you
to use the native `service` command to stop, start and restart the application.

### Passenger

**Template Variables:**

* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your Alaveteli instance
* `user`: the user that the software runs as

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/sysvinit-passenger.example > /etc/init.d/alaveteli
    popd

    chown root:alaveteli /etc/init.d/alaveteli
    chmod 754 /etc/init.d/alaveteli

Start the application:

    service alaveteli start

### Thin

**Template Variables:**

* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your Alaveteli instance
* `user`: the user that the software runs as
* `cpus`: the number of CPU cores your server has - run `nproc` to find what
  this number should be. This controls how many thin servers the daemon starts.

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      CPUS=1 \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/sysvinit-thin.example > /etc/init.d/alaveteli
    popd

    chown root:alaveteli /etc/init.d/alaveteli
    chmod 754 /etc/init.d/alaveteli

Start the application:

    service alaveteli start

## Generate alert daemon

One of the cron jobs refers to a script at `/etc/init.d/alaveteli-alert-tracks`. This
is an init script, which can be generated from the
`config/alert-tracks-debian.example` template. This script sends out emails to users subscribed to updates from the site – known as [`tracks`]({{ page.baseurl }}/docs/installing/email/#tracks-mail) – when there is something new matching their interests

**Template Variables:**

* `daemon_name`: The name of the daemon. This is set by the rake task.
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your Alaveteli instance
* `user`: the user that the software runs as
* `ruby_version`: The version of ruby that was used to install `bundler` as a gem,
  if that was neccessary. This will be used to add the user's local
  gem directory to the `PATH` used in the daemon file

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/alert-tracks-debian.example > /etc/init.d/alaveteli-alert-tracks
    popd

    chown root:alaveteli /etc/init.d/alaveteli-alert-tracks
    chmod 754 /etc/init.d/alaveteli-alert-tracks

Start the alert tracks daemon:

    service alaveteli-alert-tracks start

## Generate mail poller daemon (optional)

`config/poll-for-incoming-debian.example` is another init script, which is optional
and not required unless you want to have Alaveteli poll a POP3 mailbox for incoming
mail rather than passively accepting it via the `mailin` script. The setup for
polling is described in the documentation for [`PRODUCTION_MAILER_RETRIEVER_METHOD`]({{ page.baseurl }}/docs/customising/config#production_mailer_retriever_method), the config setting that
switches it on. If you are using polling, this daemon will check the POP3 mailbox
for new incoming emails. If you want to use polling, you should setup your install to
deliver incoming mail for requests to the mailbox, rather than into the application.

**Template Variables:**

* `daemon_name`: The name of the daemon. This is set by the rake task.
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your Alaveteli instance
* `user`: the user that the software runs as
* `ruby_version`: The version of ruby that was used to install `bundler` as a gem,
  if that was neccessary. This will be used to add the user's local
  gem directory to the `PATH` used in the daemon file

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/poll-for-incoming-debian.example > /etc/init.d/alaveteli-poll-for-incoming
    popd

    chown root:alaveteli /etc/init.d/alaveteli-poll-for-incoming
    chmod 754 /etc/init.d/alaveteli-poll-for-incoming

Start the polling daemon:

    service alaveteli-poll-for-incoming start

## Generate notifications daemon (optional)

`config/send-notifications-debian.example` is the mechanism for sending digest
notifications to Pro users. You should only enable this if you have enabled
[Alaveteli Pro]({{ page.baseurl }}/docs/pro).

**Template Variables:**

* `daemon_name`: The name of the daemon. This is set by the rake task.
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your Alaveteli instance
* `user`: the user that the software runs as
* `ruby_version`: The version of ruby that was used to install `bundler` as a gem,
  if that was neccessary. This will be used to add the user's local
  gem directory to the `PATH` used in the daemon file

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/send-notifications-debian.example > /etc/init.d/alaveteli-send-notifications
    popd

    chown root:alaveteli /etc/init.d/alaveteli-send-notifications
    chmod 754 /etc/init.d/alaveteli-send-notifications

Start the notifications daemon:

    service alaveteli-send-notifications start
