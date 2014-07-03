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

## Target operating system

These instructions assume Debian Squeeze (64-bit) or Ubuntu 12.04 LTS
(precise). Debian Squeeze is the best supported deployment platform. We also
have instructions for [installing on MacOS]({{ site.baseurl }}docs/installing/macos/).

Commands are intended to be run via the terminal or over ssh.

## Set the locale

**Debian Squeeze**

Follow the [Debian guide](https://wiki.debian.org/Locale#Standard) for configuring the locale of the operating system.

Generate the locales you wish to make available. When the interactive screen asks you to pick a default locale, choose "None", as the SSH session will provide the locale required.

    # dpkg-reconfigure locales

Start a new SSH session to use your SSH locale.

## Get Alaveteli

To start with, you may need to install git, e.g. with `sudo apt-get install
git-core`

Next, get hold of the Alaveteli source code from github:

    git clone https://github.com/mysociety/alaveteli.git
    cd alaveteli

This will get the rails-3-develop branch, which has the latest (possibly buggy)
code. If you don't want to add or try new features, swap to the master branch
(which always contains the latest stable release):

    git checkout master

## Install mySociety libraries

Next, install mySociety's common ruby libraries. To fetch the contents of the
submodules, run:

    git submodule update --init

## Install system dependencies

These are packages that the software depends on: third-party software used to
parse documents, host the site, and so on. There are also packages that contain
headers necessary to compile some of the gem dependencies in the next step.

Add the following repositories to `/etc/apt/sources.list`:

**Debian Squeeze**

    cat > /etc/apt/sources.list.d/debian-backports.list <<EOF
    deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free
    EOF

The repositories above let you install `wkhtmltopdf-static` and `bundler` using
`apt`.

**Ubuntu Precise**

    cat > /etc/apt/sources.list.d/ubuntu-extra.list <<EOF
    deb http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ precise multiverse
    deb-src http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ precise multiverse
    deb http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ precise-updates multiverse
    deb-src http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ precise-updates multiverse
    EOF

The repositories above let you install `wkhtmltopdf-static` using `apt`.
`bundler` will have to be installed manually on Ubuntu Precise.

### Packages customised by mySociety

If you're using Debian, you should add the mySociety Debian archive to your
apt sources. Note that mySociety packages are currently only built for 64-bit Debian.

    cat > /etc/apt/sources.list.d/mysociety-debian.list <<EOF
    deb http://debian.mysociety.org squeeze main
    EOF

Add the GPG key from the
[mySociety Debian Package Repository](http://debian.mysociety.org/).

    wget -O - https://debian.mysociety.org/debian.mysociety.org.gpg.key | sudo apt-key add -

You should also configure package-pinning to reduce the priority of this
repository.

    cat > /etc/apt/preferences <<EOF
    Package: *
    Pin: origin debian.mysociety.org
    Pin-Priority: 50
    EOF

If you're using some other platform, you can optionally install these
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
certain edge conditions. Until it's incorporated into an official release, you
can either hope you don't encounter the bug (it ties up a rails process until
you kill it), patch it yourself, or use the Debian package
compiled by mySociety (see link in [issue
305](https://github.com/mysociety/alaveteli/issues/305))

### Install the dependencies

Refresh the sources after adding the extra repositories:

    sudo apt-get update

Now install the packages relevant to your system:

    # Debian Squeeze
    sudo apt-get install $(cat config/packages.debian-squeeze)

    # Ubuntu Precise
    sudo apt-get install $(cat config/packages.ubuntu-precise)

Some of the files also have a version number listed in config/packages - check
that you have appropriate versions installed. Some also list "`|`" and offer a
choice of packages.

## Install Ruby dependencies

To install Alaveteli's Ruby dependencies, you need to install bundler. In
Debian, this is provided as a package (installed as part of the package install
process above). You could also install it as a gem:

    sudo gem install bundler

## Configure Database

There has been a little work done in trying to make the code work with other
databases (e.g., SQLite), but the currently supported database is PostgreSQL
("postgres").

If you don't have postgres installed:

    $ sudo apt-get install postgresql postgresql-client

Create a `foi` user from the command line, like this:

    # sudo -u postgres createuser -s -P foi

_Note:_ Leaving the password blank will cause great confusion if you're new to
PostgreSQL.

We'll create a template for our Alaveteli databases:

    # sudo -u postgres createdb -T template0 -E UTF-8 template_utf8
    # echo "update pg_database set datistemplate=true where datname='template_utf8';" > /tmp/update-template.sql
    # sudo -u postgres psql -f /tmp/update-template.sql

Then create the databases:

    # sudo -u postgres createdb -T template_utf8 -O foi alaveteli_production
    # sudo -u postgres createdb -T template_utf8 -O foi alaveteli_test
    # sudo -u postgres createdb -T template_utf8 -O foi alaveteli_development

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
[example config for Exim4]({{ site.baseurl }}docs/installing/email/).

Note that in development mode mail is handled by mailcatcher by default so
that you can see the mails in a browser - see [http://mailcatcher.me/](http://mailcatcher.me/) for more
details. Start mailcatcher by running `bundle exec mailcatcher` in your
application directory.

### Minimal

If you just want to get the tests to pass, you will at a minimum need to allow
sending emails via a `sendmail` command (a requirement met, for example, with
`sudo apt-get install exim4`).

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

`config/crontab-example` contains the cronjobs run on WhatDoTheyKnow. It's in a
strange templating format they use in mySociety. mySociety render the example
file to reference absolute paths, and then drop it in `/etc/cron.d/` on the
server.

The `ugly` format uses simple variable substitution. A variable looks like
`!!(*= $this *)!!`. The variables are:

* `vhost`: part of the path to the directory where the software is
  served from.  In the mySociety files, it usually comes as
  `/data/vhost/!!(*= $vhost *)!!` -- you should replace that whole
  port with a path to the directory where your Alaveteli software
  installation lives, e.g. `/var/www/`
* `vhost_dir`: the entire path to the directory where the software is
  served from. -- you should replace this with a path to the
  directory where your Alaveteli software installation lives,
   e.g. `/var/www/`
* `vcspath`: the name of the alaveteli checkout, e.g. `alaveteli`.
  Thus, `/data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!` might be
  replaced with `/var/www/alaveteli` in your cron tab
* `user`: the user that the software runs as
* `site`: a string to identify your alaveteli instance

There is a rake task that will help to rewrite this file into one that is
useful to you, which can be invoked with:

    bundle exec rake config_files:convert_crontab \
      DEPLOY_USER=deploy \
    VHOST_DIR=/dir/above/alaveteli \
    VCSPATH=alaveteli \
    SITE=alaveteli \
    CRONTAB=config/crontab-example > crontab

You should change the `DEPLOY_USER`, `VHOST_DIR`, `VCSPATH` and `SITE`
environment variables to match your server and installation. You should also
edit the resulting `crontab` file to customize the `MAILTO` variable.

One of the cron jobs refers to a script at `/etc/init.d/foi-alert-tracks`. This
is an init script, a copy of which lives in `config/alert-tracks-debian.ugly`.
As with the cron jobs above, replace the variables (and/or bits near the
variables) with paths to your software. You can use the rake task `rake
config_files:convert_init_script` to do this.

`config/purge-varnish-debian.ugly` is a similar init script, which is optional
and not required if you choose not to run your site behind Varnish (see below).
Either tweak the file permissions to make the scripts executable by your deploy
user, or add the following line to your sudoers file to allow these to be run
by your deploy user (named `deploy` in this case):

    deploy  ALL = NOPASSWD: /etc/init.d/foi-alert-tracks, /etc/init.d/foi-purge-varnish

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

## Troubleshooting

*   **Incoming emails aren't appearing in my Alaveteli install**

    First, you need to check that your MTA is delivering relevant
    incoming emails to the `script/mailin` command.  There are various
    ways of setting your MTA up to do this; we have documented
    [one way of doing it]({{ site.baseurl }}docs/installing/email/#troubleshooting-exim)
    in Exim, including a command you can use to check that the email
    routing is set up correctly.

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



