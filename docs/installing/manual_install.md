---
layout: page
title: Manual installation
---


# Manual Installation

<p class="lead">
    The following instructions describe the step-by-step process for
    installing Alaveteli. <em>You don't necessarily need to do it this
    way:</em> it's usually easier to use the
    <a href="{{ site.baseurl }}docs/installing/script/">installation script</a>
    or the
    <a href="{{ site.baseurl }}docs/installing/ami/">Amazon EC2 AMI</a>.
</p>

Note that there are [other ways to install Alaveteli]({{ site.baseurl }}docs/installing/).

<div class="attention-box">
  <ul>
    <li>Commands in this guide will require root privileges</li>
    <li>Commands are intended to be run via the terminal or over ssh</li>
  </ul>
</div>

## Configure the Operating System

### Target operating system

These instructions assume a 64-bit version of Debian 6 (Wheezy), Debian 7 (Squeeze)
or Ubuntu 12.04 LTS (Precise). Debian is the best supported deployment platform. We also
have instructions for [installing on MacOS]({{ site.baseurl }}docs/installing/macos/).

### Set the locale

**Debian Wheezy or Squeeze**

Follow the [Debian guide](https://wiki.debian.org/Locale#Standard) for configuring the locale of the operating system.

Generate the locales you wish to make available. When the interactive screen asks you to pick a default locale, choose "None", as the SSH session will provide the locale required.

    dpkg-reconfigure locales

Start a new SSH session to use your SSH locale.

### Update the OS

Update the Operating System with the latest packages

    apt-get update -y
    apt-get upgrade -y

`sudo` is not installed on Debian by default. Install it along with `vim` (a useful text editor) and `git` (the version control tool we'll use to get a copy of the Alaveteli code).

    apt-get install -y sudo vim git-core

### Prepare to install system dependencies using OS packages

These are packages that the software depends on: third-party software used to
parse documents, host the site, and so on. There are also packages that contain
headers necessary to compile some of the gem dependencies in the next step.

#### Using other repositories to get more recent packages

Add the following repositories to `/etc/apt/sources.list`:

**Debian Squeeze**

    cat > /etc/apt/sources.list.d/debian-extra.list <<EOF
    deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free
    deb http://the.earth.li/debian/ wheezy main contrib non-free
    EOF

The squeeze-backports repository is providing a more recent version of rubygems, and the wheezy repository is providing bundler. You should configure package-pinning to reduce the priority of the wheezy repository so other packages aren't pulled from it.

    cat >> /etc/apt/preferences <<EOF

    Package: bundler
    Pin: release n=wheezy
    Pin-Priority: 990

    Package: *
    Pin: release n=wheezy
    Pin-Priority: 50
    EOF

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
    deb http://de.archive.ubuntu.com/ubuntu/ raring universe
    deb-src http://de.archive.ubuntu.com/ubuntu/ raring universe
    EOF

The raring repo is used here to get a more recent version of bundler and pdftk. You should configure package-pinning to reduce the priority of the raring repository so other packages aren't pulled from it.

    cat >> /etc/apt/preferences <<EOF

    Package: ruby-bundler
    Pin: release n=raring
    Pin-Priority: 990

    Package: pdftk
    Pin: release n=raring
    Pin-Priority: 990

    Package: *
    Pin: release n=raring
    Pin-Priority: 50
    EOF


#### Packages customised by mySociety

If you're using Debian or Ubuntu, you should add the mySociety Debian archive to your
apt sources. Note that mySociety packages are currently only built for 64-bit Debian.

**Debian Squeeze, Wheezy or Ubuntu Precise**

    cat > /etc/apt/sources.list.d/mysociety-debian.list <<EOF
    deb http://debian.mysociety.org squeeze main
    EOF

The repository above lets you install `wkhtmltopdf-static` and `pdftk` (for squeeze) using `apt`.

Add the GPG key from the
[mySociety Debian Package Repository](http://debian.mysociety.org/).

    wget -O - https://debian.mysociety.org/debian.mysociety.org.gpg.key | apt-key add -


**Debian Wheezy or Ubuntu Precise**

You should also configure package-pinning to reduce the priority of this
repository - we only want to pull wkhtmltopdf-static from mysociety.

    cat >> /etc/apt/preferences <<EOF

    Package: *
    Pin: origin debian.mysociety.org
    Pin-Priority: 50
    EOF

**Debian Squeeze**

No special package pinning is required.

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

If you can't get an official release for your OS with the fix, you
can either hope you don't encounter the bug (it ties up a rails process until
you kill it), patch it yourself, or use the Debian package
compiled by mySociety (see link in [issue
305](https://github.com/mysociety/alaveteli/issues/305))

#### Refresh sources

Refresh the sources after adding the extra repositories:

    apt-get -y update

### Create Alaveteli User

Create a new linux user to run the Alaveteli application.

    adduser --quiet --disabled-password --gecos "Alaveteli" alaveteli

## Get Alaveteli

Create the target directory and clone the Alaveteli source code in to this directory:

    mkdir -p /var/www/alaveteli
    chown alaveteli:alaveteli /var/www/alaveteli
    sudo -u alaveteli git clone --recursive \
      --branch master \
      https://github.com/mysociety/alaveteli.git /var/www/alaveteli

This clones the master branch which always contains the latest stable release. If you want to try out the latest (possibly buggy) code you can switch to the `rails-3-develop` branch.

    pushd /var/www/alaveteli
    sudo -u alaveteli git checkout rails-3-develop 
    popd

The `--recursive` option installs mySociety's common libraries which are required to run Alaveteli.

## Install the dependencies

Now install the packages relevant to your system:

    # Debian Wheezy
    apt-get -y install $(cat /var/www/alaveteli/config/packages.debian-wheezy)

    # Debian Squeeze
    apt-get -y install $(cat /var/www/alaveteli/config/packages.debian-squeeze)

    # Ubuntu Precise
    apt-get -y install $(cat /var/www/alaveteli/config/packages.ubuntu-precise)

Some of the files also have a version number listed in config/packages - check
that you have appropriate versions installed. Some also list "`|`" and offer a
choice of packages.

To install Alaveteli's Ruby dependencies, you need to install bundler. In
Debian and Ubuntu, this is provided as a package (installed as part of the
package install process above). You could also install it as a gem:

    gem install bundler --no-rdoc --no-ri

## Configure Database

There has been a little work done in trying to make the code work with other
databases (e.g., SQLite), but the currently supported database is PostgreSQL
("postgres").

If you don't have postgres installed:

    apt-get -y install postgresql postgresql-client

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

Now you need to set up the database config file so that the application can
connect to the postgres database.

* Copy `database.yml-example` to `database.yml` in `alaveteli/config`
* Edit it to point to your local postgresql database in the development
  and test sections.

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
permissions on these databases. As they need the ability to turn off
constraints whilst running the tests they also need to be a superuser

If you don't want your database user to be a superuser, you can add this line
to the test config in `database.yml` (as seen in `database.yml-example`)

    constraint_disabling: false

## Configure email

You will need to set up an email server (MTA) to send and receive emails. Full
configuration for an MTA is beyond the scope of this document -- see this
[example configs for Exim4 and Postfix]({{ site.baseurl }}docs/installing/email/).

Note that in development mode mail is handled by mailcatcher by default so
that you can see the mails in a browser - see [http://mailcatcher.me/](http://mailcatcher.me/) for more
details. Start mailcatcher by running `bundle exec mailcatcher` in your
application directory.

### Minimal

If you just want to get the tests to pass, you will at a minimum need to allow
sending emails via a `sendmail` command (a requirement met, for example, with
`apt-get install exim4`).

### Detailed

When an authority receives an email, the email's `reply-to` field is a magic
address which is parsed and consumed by the Rails app.

To receive such email in a production setup, you will need to configure your
MTA to pipe incoming emails to the Alaveteli script `script/mailin`. Therefore,
you will need to configure your MTA to accept emails to magic addresses, and to
pipe such emails to this script.

Magic email addresses are of the form:

    <foi+request-3-691c8388@example.com>

The respective parts of this address are controlled with options in
`config/general.yml`, thus:

    INCOMING_EMAIL_PREFIX = 'foi+'
    INCOMING_EMAIL_DOMAIN = 'example.com'

When you set up your MTA, if there is some error inside Rails, the
email is returned with an exit code 75, which for Exim at least means the MTA
will try again later. Additionally, a stacktrace is emailed to `CONTACT_EMAIL`.

See [this example]({{ site.baseurl }}docs/installing/email/) for a possible configuration for Exim (>=1.9).

A well-configured installation of this code will have had Exim make
a backup copy of the email in a separate mailbox, just in case.

## Set up configs

Copy `config/general.yml-example` to `config/general.yml` and edit to your
taste.

Note that the default settings for frontpage examples are designed to work with
the dummy data shipped with Alaveteli; once you have real data, you should
certainly edit these.

The default theme is the "Alaveteli" theme. When you run `rails-post-deploy`
(see below), that theme gets installed automatically.

Finally, copy `config/newrelic.yml-example` to `config/newrelic.yml`. This file
contains configuration information for the New Relic performance management
system. By default, monitoring is switched off by the `agent_enabled: false`
setting. See New Relic's [remote performance analysis](https://github.com/newrelic/rpm) instructions for switching it on
for both local and remote analysis.


## Deployment

In the `alaveteli` directory, run:

    script/rails-post-deploy

(This will need execute privs so `chmod 755` if necessary.) This sets up
directory structures, creates logs, installs/updates themes, runs database
migrations, etc. You should run it after each new software update.

One of the things the script does is install dependencies (using `bundle
install`). Note that the first time you run it, part of the `bundle install`
that compiles `xapian-full` takes a *long* time!

If you want some dummy data to play with, you can try loading the fixtures that
the test suite uses into your development database. You can do this with:

    script/load-sample-data

Next, create the index for the search engine (Xapian):

    script/rebuild-xapian-index

If this fails, the site should still mostly run, but it's a core component so
you should really try to get this working.

## Run the Tests

Make sure everything looks OK:

    bundle exec rake spec

If there are failures here, something has gone wrong with the preceding steps
(see the next section for a common problem and workaround). You might be able
to move on to the next step, depending on how serious they are, but ideally you
should try to find out what's gone wrong.

### glibc bug workaround

There's a [bug in
glibc](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=637239) which causes
Xapian to segfault when running the tests. Although the bug report linked to
claims it's fixed in the current Debian stable, it's not as of version
`2.11.3-2`.

Until it's fixed (e.g. `libc6 2.13-26` does work), you can get the tests to
pass by setting `export LD_PRELOAD=/lib/libuuid.so.1`.

## Run the Server

Run the following to get the server running:

    bundle exec rails server  --environment=development

By default the server listens on all interfaces. You can restrict it to the
localhost interface by adding `--binding=127.0.0.1`

The server should have told you the URL to access in your browser to see the
site in action.

## Cron jobs and init scripts

The crontab and init scripts use the `.ugly` file format, which is a strange
templating format used by mySociety.

The `ugly` format uses simple variable substitution. A variable looks like
`!!(*= $this *)!!`.

### Generate crontab

`config/crontab-example` contains the cron jobs that run on
WhatDoTheyKnow. mySociety render the example file to reference absolute paths,
and then drop it in `/etc/cron.d/` on the server.

**Template Variables:**

* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `vcspath`: the name of the directory that contains the alaveteli code.
  e.g. `alaveteli`
* `user`: the user that the software runs as
* `site`: a string to identify your alaveteli instance
* `mailto`: The email address that cron output will be sent to

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    bundle exec rake config_files:convert_crontab \
      DEPLOY_USER=deploy \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      MAILTO=cron-alaveteli@example.org \
      CRONTAB=config/crontab-example > /etc/cron.d/alaveteli

### Generate alert daemon

One of the cron jobs refers to a script at `/etc/init.d/foi-alert-tracks`. This
is an init script, which can be generated from the
`config/alert-tracks-debian.ugly` template.

**Template Variables:**

* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `user`: the user that the software runs as

There is a rake task that will help to rewrite this file into one that is
useful to you. Change the variables to suit your installation.

    bundle exec rake config_files:convert_init_script \
      DEPLOY_USER=deploy \
      VHOST_DIR=/var/www \
      SCRIPT_FILE=config/alert-tracks-debian.ugly > /etc/init.d/foi-alert-tracks

### Generate varnish purge daemon

`config/purge-varnish-debian.ugly` is a similar init script, which is optional
and not required if you choose not to run your site behind Varnish (see below).

**Template Variables:**

* `daemon_name`: The name of the daemon. Set this to `purge-varnish`.
* `vhost_dir`: the full path to the directory where alaveteli is checked out.
  e.g. If your checkout is at `/var/www/alaveteli` then set this to `/var/www`
* `user`: the user that the software runs as

This template does not yet have a rake task to generate it.

### Init script permissions

Either tweak the file permissions to make the scripts executable by your deploy
user, or add the following line to your sudoers file to allow these to be run
by your deploy user (named `deploy` in this case).

    deploy ALL = NOPASSWD: /etc/init.d/foi-alert-tracks, /etc/init.d/foi-purge-varnish

There is also an example config for stopping and starting the
Alaveteli app server as a service in `config/sysvinit.example`. This
example assumes you're using Thin as an application server, so will
need tweaking for Passenger or any other app server. You can install
this by copying it to `/etc/init.d/alaveteli` and setting the
`SITE_HOME` variable to the path where Alaveteli is running, and the
`USER` variable to the Unix user that will be running Alaveteli. Once
that's done, you can restart Alaveteli with `/etc/init.d/alaveteli
restart`.

## Set up production web server

It is not recommended to run the website using the default Rails web server.
There are various recommendations here: http://rubyonrails.org/deploy

We usually use Passenger / mod_rails. The file at `conf/httpd.conf-example`
gives you an example config file for WhatDoTheyKnow. At a minimum, you should
include the following in an Apache configuration file:

    PassengerResolveSymlinksInDocumentRoot on
    PassengerMaxPoolSize 6 # Recommend setting this to 3 or less on servers with 512MB RAM

Under all but light loads, it is strongly recommended to run the server behind
an http accelerator like Varnish. A sample varnish VCL is supplied in
`conf/varnish-alaveteli.vcl`.

It's strongly recommended that you run the site over SSL. (Set FORCE_SSL to
true in config/general.yml). For this you will need an SSL certificate for your
domain and you will need to configure an SSL terminator to sit in front of
Varnish. If you're already using Apache as a web server you could simply use
Apache as the SSL terminator. A minimal configuration would look something like
this:

    <VirtualHost *:443>
        ServerName www.yourdomain

      ProxyRequests       Off
      ProxyPreserveHost On
      ProxyPass           /       http://localhost:80/
      ProxyPassReverse    /       http://localhost:80/
      RequestHeader set X-Forwarded-Proto 'https'

      SSLEngine on
      SSLProtocol all -SSLv2
      SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM

      SSLCertificateFile /etc/apache2/ssl/ssl.crt
      SSLCertificateKeyFile /etc/apache2/ssl/ssl.key
      SSLCertificateChainFile /etc/apache2/ssl/sub.class2.server.ca.pem
      SSLCACertificateFile /etc/apache2/ssl/ca.pem
      SetEnvIf User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown

    </VirtualHost>

Notice the line `RequestHeader` that sets the `X-Forwarded-Proto` header. This
is important. This ultimately tells Rails that it's serving a page over https
and so it knows to include that in any absolute urls it serves.

We have some [production server best practice
notes]({{ site.baseurl}}docs/running/server/).

## What next? 

Check out the [next steps]({{ site.baseurl }}docs/installing/next_steps/).

## Troubleshooting

*   **Incoming emails aren't appearing in my Alaveteli install**

    First, you need to check that your MTA is delivering relevant
    incoming emails to the `script/mailin` command.  There are various
    ways of setting your MTA up to do this; we have documented
    one way of doing it
    [in Exim]({{ site.baseurl }}docs/installing/email/#example-setup-on-exim4), including [a command you can use]({{ site.baseurl }}docs/installing/email/#troubleshooting-exim) to check that the email
    routing is set up correctly. We've also documented one way of setting up [Postfix]({{ site.baseurl }}docs/installing/email/#example-setup-on-postfix), with a similar [debugging command]({{ site.baseurl }}docs/installing/email/#troubleshooting-postfix).

    Second, you need to test that the mailin script itself is working
    correctly, by running it from the command line, First, find a
    valid "To" address for a request in your system.  You can do this
    through your site's admin interface, or from the command line,
    like so:

        $ ./script/console
        Loading development environment (Rails 2.3.14)
        >> InfoRequest.find_by_url_title("why_do_you_have_such_a_fancy_dog").incoming_email
        => "request-101-50929748@localhost"

    Now take the source of a valid email (there are some sample emails in
    `spec/fixtures/files/`); edit the `To:` header to match this address;
    and then pipe it through the mailin script.  A non-zero exit code
    means there was a problem.  For example:

        $ cp spec/fixtures/files/incoming-request-plain.email /tmp/
        $ perl -pi -e 's/^To:.*/To: <request-101-50929748@localhost>/' /tmp/incoming-request-plain.email
        $ ./script/mailin < /tmp/incoming-request-plain.email
        $ echo $?
        75

    The `mailin` script emails the details of any errors to
    `CONTACT_EMAIL` (from your `general.yml` file).  A common problem is
    for the user that the MTA runs as not to have write access to
    `files/raw_emails/`.

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



