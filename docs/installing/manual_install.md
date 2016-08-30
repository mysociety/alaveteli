---
layout: page
title: Manual installation
---


# Manual Installation

<p class="lead">
    The following instructions describe the step-by-step process for
    installing Alaveteli. <em>You don't necessarily need to do it this
    way:</em> it's usually easier to use the
    <a href="{{ page.baseurl }}/docs/installing/script/">installation script</a>
    or the
    <a href="{{ page.baseurl }}/docs/installing/ami/">Amazon EC2 AMI</a>.
</p>

Note that there are [other ways to install Alaveteli]({{ page.baseurl }}/docs/installing/).

<div class="attention-box">
  <ul>
    <li>Commands in this guide will require root privileges</li>
    <li>Commands are intended to be run via the terminal or over ssh</li>
  </ul>
</div>

## Configure the Operating System

### Target operating system

These instructions assume a 64-bit version of Debian 7 (Wheezy)
or Ubuntu 12.04 LTS (Precise) or 14.04 LTS (Trusty). Debian is the best supported deployment platform. We also
have instructions for [installing on MacOS]({{ page.baseurl }}/docs/installing/macos/).

### Set the locale

**Debian Wheezy**

Follow the [Debian guide](https://wiki.debian.org/Locale#Standard) for configuring the locale of the operating system.

Generate the locales you wish to make available. When the interactive screen asks you to pick a default locale, choose "None", as the SSH session will provide the locale required.

    dpkg-reconfigure locales

Start a new SSH session to use your SSH locale.

**Ubuntu Precise/Trusty**

Unset the default locale, as the SSH session should provide the locale required.

    update-locale LC_ALL=

Start a new SSH session to use your SSH locale.

If you're going to run the tests, you'll need to have the `en_GB` and `en_GB.UTF-8` locales installed.

    locale-gen en_GB
    locale-gen en_GB.UTF-8
    update-locale

### Update the OS

Update the Operating System with the latest packages

    apt-get update -y
    apt-get upgrade -y

`sudo` is not installed on Debian by default. Install it along with `git` (the version control tool we'll use to get a copy of the Alaveteli code).

    apt-get install -y sudo git-core

### Prepare to install system dependencies using OS packages

These are packages that the software depends on: third-party software used to
parse documents, host the site, and so on. There are also packages that contain
headers necessary to compile some of the gem dependencies in the next step.

#### Using other repositories to get more recent packages

Add the following repositories to `/etc/apt/sources.list`:

**Debian Wheezy**

    cat > /etc/apt/sources.list.d/debian-extra.list <<EOF
    # Debian mirror to use, including contrib and non-free:
    deb http://the.earth.li/debian/ wheezy main contrib non-free
    deb-src http://the.earth.li/debian/ wheezy main contrib non-free

    # Security Updates:
    deb http://security.debian.org/ wheezy/updates main non-free
    deb-src http://security.debian.org/ wheezy/updates main non-free
    EOF

**Ubuntu Precise**

    cat > /etc/apt/sources.list.d/ubuntu-extra.list <<EOF
    deb http://de.archive.ubuntu.com/ubuntu/ precise multiverse
    deb-src http://de.archive.ubuntu.com/ubuntu/ precise multiverse
    deb http://de.archive.ubuntu.com/ubuntu/ precise-updates multiverse
    deb-src http://de.archive.ubuntu.com/ubuntu/ precise-updates multiverse
    deb http://de.archive.ubuntu.com/ubuntu/ trusty universe
    deb-src http://de.archive.ubuntu.com/ubuntu/ trusty universe
    EOF

The trusty repo is used here to get a more recent version of bundler. You should configure package-pinning to reduce the priority of the trusty repository so other packages aren't pulled from it.

    cat >> /etc/apt/preferences <<EOF

    Package: ruby-bundler
    Pin: release n=trusty
    Pin-Priority: 990

    Package: *
    Pin: release n=trusty
    Pin-Priority: 50
    EOF


#### Packages customised by mySociety

If you're using Debian or Ubuntu, you should add the mySociety Debian archive to your
apt sources. Note that mySociety packages are currently only built for 64-bit Debian.

**Debian Wheezy or Ubuntu Precise**

    cat > /etc/apt/sources.list.d/mysociety-debian.list <<EOF
    deb http://debian.mysociety.org squeeze main
    EOF

The repository above lets you install `wkhtmltopdf-static` using `apt`.

Add the GPG key from the
[mySociety Debian Package Repository](http://debian.mysociety.org/).

    wget -O - https://debian.mysociety.org/debian.mysociety.org.gpg.key | apt-key add -

**Ubuntu Precise only**

    cat > /etc/apt/sources.list.d/mysociety-launchpad.list <<EOF
    deb http://ppa.launchpad.net/mysociety/alaveteli/ubuntu precise main
    deb-src http://ppa.launchpad.net/mysociety/alaveteli/ubuntu precise main
    EOF

The repository above lets you install a recent version of `pdftk` using `apt`.

Add the GPG key from the
[mySociety Alaveteli Ubuntu Package Repository](https://launchpad.net/~mysociety/+archive/ubuntu/alaveteli).

    apt-get install -y python-software-properties
    add-apt-repository -y ppa:mysociety/alaveteli

**Debian Wheezy or Ubuntu Precise**

You should also configure package-pinning to reduce the priority of the
mysociety Debian repository - we only want to pull wkhtmltopdf-static
from mysociety.

    cat >> /etc/apt/preferences <<EOF

    Package: *
    Pin: origin debian.mysociety.org
    Pin-Priority: 50
    EOF

#### Other platforms
If you're using some other linux platform, you can optionally install these
dependencies manually, as follows:

1. If you would like users to be able to get pretty PDFs as part of the
downloadable zipfile of their request history, install
[wkhtmltopdf](http://code.google.com/p/wkhtmltopdf/downloads/list). We
recommend downloading the latest, statically compiled version from the project
website, as this allows running headless (that is, without a graphical interface
running) on Linux. If you do install `wkhtmltopdf`, you need to edit a setting
in the config file to point to it (see below). If you don't install it,
everything will still work, but users will get ugly, plain text versions of
their requests when they download them.

2. Version 1.44 of `pdftk` contains a bug which makes it loop forever in
certain edge conditions. This is fixed in the standard 1.44.7 package which is available in wheezy (Debian) and raring (Ubuntu).

If you can't get an official release for your OS with the fix, you can
either hope you don't encounter the bug (it ties up a rails process
until you kill it), patch it yourself, or use the
[Debian](http://debian.mysociety.org/dists/squeeze/main/binary-amd64/)
or
[Ubuntu](https://launchpad.net/~mysociety/+archive/ubuntu/alaveteli/+packages)
packages compiled by mySociety.

#### Refresh sources

Refresh the sources after adding the extra repositories:

    apt-get -y update

### Create Alaveteli User

Create a new linux user to run the Alaveteli application. Add them to the 'adm' group
so that they can read the mail log files.

    adduser --quiet --disabled-password --gecos "Alaveteli" alaveteli
    usermod -a -G adm alaveteli


## Get Alaveteli

Create the target directory and clone the Alaveteli source code in to this directory:

    mkdir -p /var/www/alaveteli
    chown alaveteli:alaveteli /var/www
    chown alaveteli:alaveteli /var/www/alaveteli
    cd /home/alaveteli
    sudo -u alaveteli git clone --recursive \
      --branch master \
      https://github.com/mysociety/alaveteli.git /var/www/alaveteli

This clones the master branch which always contains the latest stable release. If you want to try out the latest (possibly buggy) code you can switch to the `develop` branch.

    pushd /var/www/alaveteli
    sudo -u alaveteli git checkout develop
    sudo -u alaveteli git submodule update
    popd

The `--recursive` option installs mySociety's common libraries which are required to run Alaveteli.

## Install the dependencies

Now install the packages relevant to your system:

    # Debian Wheezy
    apt-get -y install $(cat /var/www/alaveteli/config/packages.debian-wheezy)

    # Ubuntu Precise
    apt-get -y install $(cat /var/www/alaveteli/config/packages.ubuntu-precise)

Some of the files also have a version number listed in config/packages - check
that you have appropriate versions installed. Some also list "`|`" and offer a
choice of packages.

<div class="attention-box">

<strong>Note:</strong> To install Alaveteli's Ruby dependencies, you need to install bundler. In
Debian and Ubuntu, this is provided as a package (installed as part of the
package install process above). For other OSes, you could also install it as a gem:

   <pre><code> gem install bundler --no-rdoc --no-ri</code></pre>

</div>


## Configure Database

There has been a little work done in trying to make the code work with other
databases (e.g., SQLite), but the currently supported database is PostgreSQL
("postgres").

Create a `foi` user from the command line, like this:

    sudo -u postgres createuser -s -P foi

_Note:_ Leaving the password blank will cause great confusion if you're new to
PostgreSQL.

We'll create a template for our Alaveteli databases:

    sudo -u postgres createdb -T template0 -E UTF-8 template_utf8
    echo "update pg_database set datistemplate=true where datname='template_utf8';" > /tmp/update-template.sql
    sudo -u postgres psql -f /tmp/update-template.sql
    rm /tmp/update-template.sql

Then create the databases:

    sudo -u postgres createdb -T template_utf8 -O foi alaveteli_production
    sudo -u postgres createdb -T template_utf8 -O foi alaveteli_test
    sudo -u postgres createdb -T template_utf8 -O foi alaveteli_development

## Configure email

You will need to set up an email server – or Mail Transfer Agent (MTA) – to
send and receive emails.

Full configuration for an MTA is beyond the scope of this document -- see the guide for [configuring the Exim4 or Postfix MTAs]({{ page.baseurl }}/docs/installing/email/).

Note that in development mode mail is handled by [`mailcatcher`](http://mailcatcher.me/) by default so
that you can see the mails in a browser. Start mailcatcher by running `bundle exec mailcatcher` in the application directory.

## Configure Alaveteli

Alaveteli has three main configuration files:

  - `config/database.yml`: Configures Alaveteli to communicate with the database
  - `config/general.yml`: The general Alaveteli application settings
  - `config/newrelic.yml`: Configuration for the [NewRelic](http://newrelic.com) monitoring service

Copy the configuration files and update their permissions:

    cp /var/www/alaveteli/config/database.yml-example /var/www/alaveteli/config/database.yml
    cp /var/www/alaveteli/config/general.yml-example /var/www/alaveteli/config/general.yml
    cp /var/www/alaveteli/config/newrelic.yml-example /var/www/alaveteli/config/newrelic.yml
    chown alaveteli:alaveteli /var/www/alaveteli/config/{database,general,newrelic}.yml
    chmod 640 /var/www/alaveteli/config/{database,general,newrelic}.yml

### database.yml

Now you need to set up the database config file so that the application can
connect to the postgres database.

Edit each section to point to the relevant local postgresql database.

Example `development` section of `config/database.yml`:

    development:
      adapter: postgresql
      template: template_utf8
      database: alaveteli_development
      username: foi
      password: secure-password-here
      host: localhost
      port: 5432

Make sure that the user specified in `database.yml` exists, and has full
permissions on these databases.

As the user needs the ability to turn off constraints whilst running the tests
they also need to be a superuser (clarification: a <em>Postgres</em> superuser,
not an Alaveteli
<a href="{{ page.baseurl }}/docs/glossary/#super" class="glossary__link">superuser</a>).
If you don't want your database user to be a superuser, you can add this line
to the `test` section in `database.yml` (as seen in `config/database.yml-example`):

    constraint_disabling: false

### general.yml

We have a full [guide to Alaveteli configuration]({{ page.baseurl }}/docs/customising/config/) which covers all the settings in `config/general.yml`.

_Note:_ If you are setting up Alaveteli to run in production, set the [`STAGING_SITE`]({{ page.baseurl }}/docs/customising/config/#staging_site) variable to `0` in `/var/www/alaveteli/config/general.yml` now.

    STAGING_SITE: 0

The default settings for frontpage examples are designed to work with
the dummy data shipped with Alaveteli; once you have real data, you should
certainly edit these.

The default theme is the ["Alaveteli" theme](https://github.com/mysociety/alavetelitheme). When you run `rails-post-deploy` (see below), that theme gets installed automatically.

### newrelic.yml

This file contains configuration information for the New Relic performance
management system. By default, monitoring is switched off by the
`agent_enabled: false` setting. See New Relic's [remote performance analysis](https://github.com/newrelic/rpm) instructions for switching it on
for both local and remote analysis.

## Deployment

You should run the `rails-post-deploy` script after each new software upgrade:

    sudo -u alaveteli RAILS_ENV=production \
      /var/www/alaveteli/script/rails-post-deploy

This installs Ruby dependencies, installs/updates themes, runs database
migrations, updates shared directories and runs other tasks that need to be run
after a software update, like precompiling static assets for a production install.

That the first time you run this script can take a *long* time, as it must
compile native dependencies for `xapian-full`.

Create the index for the search engine (Xapian):

    sudo -u alaveteli RAILS_ENV=production \
      /var/www/alaveteli/script/rebuild-xapian-index

If this fails, the site should still mostly run, but it's a core component so
you should really try to get this working.

<div class="attention-box">
  Note that we set <code>RAILS_ENV=production</code>. Use
  <code>RAILS_ENV=development</code> if you are installing Alaveteli to make
  changes to the code.
</div>

## Configure the Application Server

Alaveteli can run under many popular application servers. mySociety recommends
the use of [Phusion Passenger](https://www.phusionpassenger.com) (AKA
mod_rails) or [thin](http://code.macournoyer.com/thin).

### Using Phusion Passenger

Passenger is the recommended application server as it is well proven in
production environments. It is implemented as an Apache mod, so it cannot be
run independently.

    apt-get install -y libapache2-mod-passenger

See later in the guide for configuring the Apache web server with Passenger.

### Using Thin

Thin is a lighter-weight application server which can be run independently of
a web server. Thin will be installed in the application bundle and used to run Alaveteli by default.

Run the following to get the server running:

    cd /var/www/alaveteli
    bundle exec thin \
      --environment=production \
      --user=alaveteli \
      --group=alaveteli \
      --servers=1 \
      start

By default the server listens on all interfaces. You can restrict it to the
localhost interface by adding `--address=127.0.0.1`

The server should have told you the URL to access in your browser to see the
site in action.

You can daemonize the process by starting it with the `--daemonize` option.

Later in this guide we'll actually create a SysVinit daemon to run the application, so stop any thin processes you've started here.

## Cron jobs and Daemons

The crontab and init scripts use the `ugly` file format, which is a strange
templating format used by mySociety.

The `ugly` format uses simple variable substitution. A variable looks like
`!!(*= $this *)!!`.

### Generate crontab

`config/crontab-example` contains the cron jobs that run on
Alaveteli. Rewrite the example file to replace the variables,
and then drop it in `/etc/cron.d/` on the server.

**Template Variables:**

* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the alaveteli code.
  e.g. `alaveteli`
* `user`: the user that the software runs as
* `site`: a string to identify your alaveteli instance
* `mailto`: The email address or local account that cron output will be sent to - setting an email address depends on your MTA having been configured for remote delivery.

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

### Generate application daemon

Generate a daemon based on the application server you installed. This allows you
to use the native `service` command to stop, start and restart the application.

#### Passenger

**Template Variables:**

* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your alaveteli instance
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

#### Thin

**Template Variables:**

* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your alaveteli instance
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

### Generate alert daemon

One of the cron jobs refers to a script at `/etc/init.d/alaveteli-alert-tracks`. This
is an init script, which can be generated from the
`config/alert-tracks-debian.example` template. This script sends out emails to users subscribed to updates from the site – known as [`tracks`]({{ page.baseurl }}/docs/installing/email/#tracks-mail) – when there is something new matching their interests

**Template Variables:**

* `daemon_name`: The name of the daemon. This is set by the rake task.
* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your alaveteli instance
* `user`: the user that the software runs as

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

### Generate varnish purge daemon

`config/purge-varnish-debian.example` is a similar init script, which is optional
and not required if you choose not to run your site behind Varnish (see below). It notifies Varnish of cached pages that need to be purged from Varnish's cache. It will not run if Varnish is not installed.

**Template Variables:**

* `daemon_name`: The name of the daemon. This is set by the rake task.
* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the alaveteli code.
  e.g. `alaveteli`
* `site`: a string to identify your alaveteli instance
* `user`: the user that the software runs as

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/purge-varnish-debian.example > /etc/init.d/alaveteli-purge-varnish
    popd

    chown root:alaveteli /etc/init.d/alaveteli-purge-varnish
    chmod 754 /etc/init.d/alaveteli-purge-varnish

Start the alert tracks daemon:

    service alaveteli-purge-varnish start


## Configure the web server

In almost all scenarios, we recommend running the Alaveteli Rails application
behind a web server. This allows the web server to serve static content without
going through the Rails stack, which improves performance.

We recommend two main combinations of application and web server:

- Apache &amp; Passenger
- Nginx &amp; Thin

There are ways to run Passenger with Nginx, and indeed Thin with Apache, but
that's out of scope for this guide. If you want to do something that isn't
documented here, get in touch on [alaveteli-dev](https://groups.google.com/forum/#!forum/alaveteli-dev) and we'll
be more than happy to help you get set up.

You should have already installed an application server if you have followed
this guide, so pick the appropriate web server to configure.

### Apache (with Passenger)

Install Apache with the Suexec wrapper:

    apt-get install -y apache2
    apt-get install -y apache2-suexec

Enable the required modules

    a2enmod actions
    a2enmod expires
    a2enmod headers
    a2enmod passenger
    a2enmod proxy
    a2enmod proxy_http
    a2enmod rewrite
    a2enmod suexec

Create a directory for optional Alaveteli configuration

    mkdir -p /etc/apache2/vhost.d/alaveteli

Copy the example VirtualHost configuration file. You will need to change all
occurrences of `www.example.com` to your URL

**Debian Wheezy and Ubuntu Precise**

    cp /var/www/alaveteli/config/httpd.conf-example \
      /etc/apache2/sites-available/alaveteli

**Ubuntu Trusty**

    cp /var/www/alaveteli/config/httpd.conf-example \
      /etc/apache2/sites-available/alaveteli.conf

Disable the default site and enable the `alaveteli` VirtualHost

**Debian Wheezy and Ubuntu Precise**

    a2dissite default
    a2ensite alaveteli

**Ubuntu Trusty**

    a2dissite 000-default.conf
    a2ensite alaveteli.conf

Check the configuration and fix any issues

    apachectl configtest

Restart apache to load the new Alaveteli config

    service apache2 graceful

It's strongly recommended that you run the site over SSL. (Set `FORCE_SSL` to
true in `config/general.yml`). For this you will need an SSL certificate for your domain.

Enable the SSL apache mod

    a2enmod ssl

Copy the SSL configuration – again changing `www.example.com` to your domain –
and enable the VirtualHost

**Debian Wheezy and Ubuntu Precise**

    cp /var/www/alaveteli/config/httpd-ssl.conf.example \
      /etc/apache2/sites-available/alaveteli_https
    a2ensite alaveteli_https

**Ubuntu Trusty**

    cp /var/www/alaveteli/config/httpd-ssl.conf.example \
      /etc/apache2/sites-available/alaveteli_https.conf
    a2ensite alaveteli_https.conf

Force HTTPS requests from the HTTP VirtualHost

    cp /var/www/alaveteli/config/httpd-force-ssl.conf.example \
      /etc/apache2/vhost.d/alaveteli/force-ssl.conf

If you are testing Alaveteli or setting up an internal staging site, generate
self-signed SSL certificates. **Do not use self-signed certificates for a
production server**. Replace `www.example.com` with your domain name.

    openssl genrsa -out /etc/ssl/private/www.example.com.key 2048
    chmod 640 /etc/ssl/private/www.example.com.key

    openssl req -new -x509 \
      -key /etc/ssl/private/www.example.com.key \
      -out /etc/ssl/certs/www.example.com.cert \
      -days 3650 \
      -subj /CN=www.example.com
    chmod 640 /etc/ssl/certs/www.example.com.cert

Check the configuration and fix any issues

    apachectl configtest

Restart apache to load the new Alaveteli config. This will also restart
Passenger (the application server).

    service apache2 graceful

### Nginx (with Thin)

Install nginx

    apt-get install -y nginx

#### Running over SSL

It's strongly recommended that you run the site over SSL. (Set `FORCE_SSL` to
true in `config/general.yml`). For this you will need an SSL certificate for your domain.

Copy the SSL configuration – changing `www.example.com` to your domain –
and enable the `alaveteli_https` server, disabling the default site.

    cp /var/www/alaveteli/config/nginx-ssl.conf.example \
      /etc/nginx/sites-available/alaveteli_https
    rm /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/alaveteli_https \
      /etc/nginx/sites-enabled/alaveteli_https

<div class="attention-box">
  <strong>Note:</strong> For historical reasons, <code>nginx-ssl.conf.example</code> has the path to Alaveteli set as <code>/var/www/alaveteli/alaveteli</code> – you will need to manually change this to <code>/var/www/alaveteli</code>, or to the root of your Alaveteli install
</div>

If you are testing Alaveteli or setting up an internal staging site, generate
self-signed SSL certificates. **Do not use self-signed certificates for a
production server**. Replace `www.example.com` with your domain name.

    openssl genrsa -out /etc/ssl/private/www.example.com.key 2048
    chmod 640 /etc/ssl/private/www.example.com.key

    openssl req -new -x509 \
      -key /etc/ssl/private/www.example.com.key \
      -out /etc/ssl/certs/www.example.com.cert \
      -days 3650 \
      -subj /CN=www.example.com
    chmod 640 /etc/ssl/certs/www.example.com.cert

If you have configured thin to use more than one server, you will need to edit the alaveteli upstream
directive in your <code>/etc/nginx/sites-enabled/alaveteli_https</code> file so
that it has a `server` line for each instance you are running (otherwise nginx
will only know how to send requests to the first server process). Each address
line needs to have a unique port number - start at `3000` and add `1` for each
new process. For example if you started your cluster with 4 servers, the
upstream directive should look like this:

    upstream alaveteli {
        server 127.0.0.1:3000;
        server 127.0.0.1:3001;
        server 127.0.0.1:3002;
        server 127.0.0.1:3003;
    }

Check the configuration and fix any issues

    service nginx configtest

Reload the new nginx configuration and restart the application

    service nginx reload
    service alaveteli restart

#### Running without SSL

Set `FORCE_SSL` to
false in `config/general.yml`. Copy the example nginx config

    cp /var/www/alaveteli/config/nginx.conf.example \
      /etc/nginx/sites-available/alaveteli

<div class="attention-box">
  <strong>Note:</strong> For historical reasons, <code>nginx.conf.example</code> has the path to Alaveteli set as <code>/var/www/alaveteli/alaveteli</code> – you will need to manually change this to <code>/var/www/alaveteli</code>, or to the root of your Alaveteli install
</div>

Disable the default site and enable the `alaveteli` server

    rm /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/alaveteli \
      /etc/nginx/sites-enabled/alaveteli

If you have configured thin to use more than one server, you will need to edit the alaveteli upstream
directive in your <code>/etc/nginx/sites-enabled/alaveteli</code> file so
that it has a `server` line for each instance you are running (otherwise nginx
will only know how to send requests to the first server process). Each address
line needs to have a unique port number - start at `3000` and add `1` for each
new process. For example if you started your cluster with 4 servers, the
upstream directive should look like this:

    upstream alaveteli {
        server 127.0.0.1:3000;
        server 127.0.0.1:3001;
        server 127.0.0.1:3002;
        server 127.0.0.1:3003;
    }

Check the configuration and fix any issues

    service nginx configtest

Start the rails application with thin (if you haven't already).

    service alaveteli start

Reload the nginx configuration

    service nginx reload


---

## Add varnish as an HTTP accelerator

Under all but light loads, it is strongly recommended to run the server behind
an http accelerator like Varnish. A sample varnish VCL is supplied in
`conf/varnish-alaveteli.vcl`.

If you are using SSL you will need to configure an SSL terminator to sit in
front of Varnish. If you're already using Apache as a web server you could
simply use Apache as the SSL terminator.

We have some [production server best practice
notes]({{ page.baseurl }}/docs/running/server/).

## What next?

Check out the [next steps]({{ page.baseurl }}/docs/installing/next_steps/).

## Troubleshooting

*   **Run the Tests**

    Make sure everything looks OK. As the alaveteli user, run:

        bundle exec rake spec

    If there are failures here, something has gone wrong with the preceding
    steps (see the next section for a common problem and workaround). You might
    be able to move on to the [next steps]({{ page.baseurl }}/docs/installing/next_steps/), depending on how serious they are, but
    ideally you should try to find out what's gone wrong.


<div class="attention-box">
  <strong>Note:</strong> If you have setup your install of Alaveteli for production, you will need to temporarily remove the file <code>config/rails_env.rb</code>, which is used to force the rails environment to production, and edit your <code>.bundle/config</code> file to remove the <code>BUNDLE_WITHOUT</code> line that excludes development dependencies. After you have done this, as the alaveteli user, run <code>bundle install</code>. You will also need to make alaveteli the owner of <code>/var/www/alaveteli/log/development.log</code>, and run the database migrations.

    <pre><code>chown alaveteli:alaveteli /var/www/alaveteli/log/development.log
sudo -u alaveteli bundle exec rake db:migrate</code></pre>

You should then be able to run the tests. Don't forget to restore <code>config/rails_env.rb</code> when you're done. You will probably see some errors from cron jobs in the meantime, as they'll be running in development mode.

</div>

*   **When running tests, I see a failure with "PG::UndefinedObject: ERROR:
    collation "en_GB" for encoding "UTF8" does not exist"**

    You can install the "en_GB" collation manually:

        psql -c 'CREATE COLLATION "en_GB" (LOCALE = "en_GB.utf8");' -U postgres alaveteli_test

*   **Incoming emails aren't appearing in my Alaveteli install**

    See the [general email troubleshooting guide]({{ page.baseurl }}/docs/installing/email#general-email-troubleshooting).

*   **Various tests fail with "*Your PostgreSQL connection does not support
    unescape_bytea. Try upgrading to pg 0.9.0 or later.*"**

    You have an old version of `pg`, the ruby postgres driver.  In
    Ubuntu, for example, this is provided by the package `libdbd-pg-ruby`.

    Try upgrading your system's `pg` installation, or installing the pg
    gem with `gem install pg`

*   **Some of the tests relating to mail are failing, with messages like
    "*when using TMail should load an email with funny MIME settings'
    FAILED*"**

    This sounds like the tests are running using the `production`
    environment, rather than the `test` environment, for some reason.

*   **Non-ASCII characters are being displayed as asterisks in my incoming messages**

    We rely on `elinks` to convert HTML email to plain text.
    Normally, the encoding should just work, but under some
    circumstances it appears that `elinks` ignores the parameters
    passed to it from Alaveteli.

    To force `elinks` always to treat input as UTF8, add the following
    to `/etc/elinks/elinks.conf`:

        set document.codepage.assume = "utf-8"
        set document.codepage.force_assumed = 1

    You should also check that your locale is set up correctly.  See
    [this issue followup](https://github.com/mysociety/alaveteli/issues/128#issuecomment-1814845)
    for further discussion.

*   **I'm seeing `rake: command not found` when running the post install script**

    The script uses `rake`.

    It may be that the binaries installed by bundler are not put in the
    system `PATH`; therefore, in order to run `rake` (needed for
    deployments), you may need to do something like:

        ln -s /usr/lib/ruby/gems/1.8/bin/rake /usr/local/bin/



