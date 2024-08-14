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

* `deploy_user`: the user that the software runs as
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`
* `mailto`: The email address or local account that cron output will be sent to
  - setting an email address depends on your MTA having been configured for
  remote delivery.

There is a rake task that will help to rewrite this file into one that is
useful to you. This example sends cron output to the local `alaveteli` user.
Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_crontab \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      MAILTO=alaveteli \
      CRONTAB=/var/www/alaveteli/config/crontab-example > /etc/cron.d/alaveteli
    popd

    chown root:alaveteli /etc/cron.d/alaveteli
    chmod 754 /etc/cron.d/alaveteli

Note: If you are generating the crontab manually, rather than with this rake task,
you will need to add a line to periodically check on each daemon you install following
the instructions below, as follows, making sure to replace DAEMON_NAME with the name
of the daemon file:

    5,15,25,35,45,55 * * * * alaveteli systemctl is-active --quiet DAEMON_NAME || sudo systemctl start DAEMON_NAME

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

### Puma

Puma is a fast, multithreaded, and highly concurrent HTTP server for Ruby and
Rack applications.

**Template Variables:**

* `deploy_user`: the user that the software runs as
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_daemon \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      DAEMON=puma.service > /etc/systemd/system/alaveteli-puma.service
    popd

    chown root:alaveteli /etc/systemd/system/alaveteli-puma.service
    chmod 754 /etc/systemd/system/alaveteli-puma.service

Enable the service:

    systemctl enable alaveteli-puma.service

Start the application:

    systemctl start alaveteli-puma.service

## Sidekiq - Background job processor

Sidekiq is a background processing daemon that handles asynchronous tasks for
Alaveteli.

**Template Variables:**

* `deploy_user`: the user that the software runs as
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_daemon \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      DAEMON=sidekiq.service > /etc/systemd/system/alaveteli-sidekiq.service
    popd

    chown root:alaveteli /etc/systemd/system/alaveteli-sidekiq.service
    chmod 754 /etc/systemd/system/alaveteli-sidekiq.service

Enable the service:

    systemctl enable alaveteli-sidekiq.service

Start the background job queue:

    systemctl start alaveteli-sidekiq.service

## Generate alert daemon

This daemon sends out emails to users subscribed to updates from the site –
known as [`tracks`]({{ page.baseurl }}/docs/installing/email/#tracks-mail) –
when there is something new matching their interests

**Template Variables:**

* `deploy_user`: the user that the software runs as
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_daemon \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      DAEMON=alert-tracks.service > /etc/systemd/system/alaveteli-alert-tracks.service
    popd

    chown root:alaveteli /etc/systemd/system/alaveteli-alert-tracks.service
    chmod 754 /etc/systemd/system/alaveteli-alert-tracks.service

Enable the service:

    systemctl enable alaveteli-alert-tracks.service

Start the alert tracks daemon:

    systemctl start alaveteli-alert-tracks.service

## Generate mail poller daemon (optional)

`config/poll-for-incoming.service` is another daemon, which is optional
and not required unless you want to have Alaveteli poll a POP3 mailbox for incoming
mail rather than passively accepting it via the `mailin` script. The setup for
polling is described in the documentation for [`PRODUCTION_MAILER_RETRIEVER_METHOD`]({{ page.baseurl }}/docs/customising/config#production_mailer_retriever_method), the config setting that
switches it on. If you are using polling, this daemon will check the POP3 mailbox
for new incoming emails. If you want to use polling, you should setup your install to
deliver incoming mail for requests to the mailbox, rather than into the application.

**Template Variables:**

* `deploy_user`: the user that the software runs as
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_daemon \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      DAEMON=poll-for-incoming.service > /etc/systemd/system/alaveteli-poll-for-incoming.service
    popd

    chown root:alaveteli /etc/systemd/system/alaveteli-poll-for-incoming.service
    chmod 754 /etc/systemd/system/alaveteli-poll-for-incoming.service

Enable the service:

    systemctl enable alaveteli-poll-for-incoming.service

Start the polling daemon:

    systemctl start alaveteli-poll-for-incoming.service

## Generate notifications daemon (optional)

`config/send-notifications.service` is the mechanism for sending digest
notifications to Pro users. You should only enable this if you have enabled
[Alaveteli Pro]({{ page.baseurl }}/docs/pro).

**Template Variables:**

* `deploy_user`: the user that the software runs as
* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_daemon \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      DAEMON=send-notifications.service > /etc/systemd/system/alaveteli-send-notifications.service
    popd

    chown root:alaveteli /etc/systemd/system/alaveteli-send-notifications.service
    chmod 754 /etc/systemd/system/alaveteli-send-notifications.service

Enable the service:

    systemctl enable alaveteli-send-notifications.service

Start the notifications daemon:

    systemctl start alaveteli-send-notifications.service

## Generate logrotate configuation (optional)

`config/logrotate-example` contains an example configuration for logrotate,
a utility that manages the automatic rotation and compression of log files.
This tool is crucial for ensuring log files do not consume excessive disk
space over time.

**Template Variables:**

* `vhost_dir`: the full path to the directory where Alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the Alaveteli code.
  e.g. `alaveteli`

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      FILE=config/logrotate-example > /etc/logrotate.d/alaveteli
    popd
