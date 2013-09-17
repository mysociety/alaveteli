These instructions assume Debian Squeeze (64-bit) or Ubuntu 12.04 LTS (precise).
[Install instructions for OS X](https://github.com/mysociety/alaveteli/wiki/OS-X-Quickstart)
are under development.  Debian Squeeze is the best supported
deployment platform.

Commands are intended to be run via the terminal or over ssh.

As an aid to evaluation, there is an
[Amazon AMI](https://github.com/mysociety/alaveteli/wiki/Alaveteli-ec2-ami)
with all these steps configured.  It is *not* production-ready.

# Get Alaveteli

To start with, you may need to install git, e.g. with `sudo apt-get
install git-core`

Next, get hold of the Alaveteli source code from github:

    git clone https://github.com/mysociety/alaveteli.git
    cd alaveteli

This will get the development branch, which has the latest (possibly
buggy) code. If you don't want to add or try new features, swap to the
master branch (which always contains the latest stable release):

    git checkout master

# Package pinning

You need to configure [apt-pinning](http://wiki.debian.org/AptPreferences#Pinning-1) preferences in order to prevent packages being pulled from the debian wheezy distribution in preference to the stable distribution once you have added the wheezy repository as described below.

In order to configure apt-pinning and to keep most packages coming from the Debian stable repository while installing the ones required from wheezy and the mySociety repository you need to run the following commands:

      echo "Package: *" >> /tmp/preferences
      echo "Pin: release a=squeeze-backports">> /tmp/preferences
      echo "Pin-Priority: 200" >> /tmp/preferences
      echo "" >> /tmp/preferences
      echo "Package: *" >> /tmp/preferences
      echo "Pin: release a=wheezy">> /tmp/preferences
      echo "Pin-Priority: 50" >> /tmp/preferences
      sudo cp /tmp/preferences /etc/apt/
      rm /tmp/preferences

# Install system dependencies

These are packages that the software depends on: third-party software
used to parse documents, host the site, etc.  There are also packages
that contain headers necessary to compile some of the gem dependencies
in the next step.

If you are running Debian, add the following repositories to
`/etc/apt/sources.list` and run `apt-get update`:

    deb http://debian.mysociety.org squeeze main
    deb http://ftp.debian.org/debian/ wheezy main non-free contrib
    deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free

The repositories above allow us to install the packages
`wkhtmltopdf-static` and `bundler` using `apt`; so if you're running
Ubuntu, you won't be able to use the above repositories, and you will
need to comment out those two lines in `config/packages` before
following the next step (and install bundler manually).

Now install the packages that are listed in config/packages using apt-get
e.g.:

    sudo apt-get install `cut -d " " -f 1 config/packages | grep -v "^#"`

Some of the files also have a version number listed in config/packages
- check that you have appropriate versions installed. Some also list
"|" and offer a choice of packages.

# Install Ruby dependencies

To install Alaveteli's Ruby dependencies, we need to install
bundler.  In Debian, this is provided as a package (installed as part
of the package install process above).  You could also install it as a
gem:

    sudo gem1.8 install bundler

# Install mySociety libraries

You will also want to install mySociety's common ruby libraries and the Rails
code. Run:

    git submodule update --init

to fetch the contents of the submodules.

## Packages customised by mySociety

Debian users should add the mySociety debian archive to their
`/etc/apt/sources.list` as described above.  Doing this and following
the above instructions should install a couple of custom
dependencies. Users of other platforms can optionally install these
dependencies manually, as follows:

1. If you would like users to be able to download pretty PDFs as part of
the downloadable zipfile of their request history, you should install
[wkhtmltopdf](http://code.google.com/p/wkhtmltopdf/downloads/list).
We recommend downloading the latest, statically compiled version from
the project website, as this allows running headless (i.e. without a
graphical interface running) on Linux.  If you do install
`wkhtmltopdf`, you need to edit a setting in the config file to point
to it (see below).  If you don't install it, everything will still
work, but users will get ugly, plain text versions of their requests
when they download them.

2. Version 1.44 of `pdftk` contains a bug which makes it to loop forever
in certain edge conditions.  Until it's incorporated into an official
release, you can either hope you don't encounter the bug (it ties up a
rails process until you kill it) you'll need to patch it yourself or
use the Debian package compiled by mySociety (see link in
[issue 305](https://github.com/mysociety/alaveteli/issues/305))


# Configure Database

There has been a little work done in trying to make the code work with
other databases (e.g. SQLite), but the currently supported database is
PostgreSQL.

If you don't have it installed:

    apt-get install postgresql postgresql-client

Now we need to set up the database config file to contain the name,
username and password of your postgres database.

* copy `database.yml-example` to `database.yml` in `alaveteli/config`
* edit it to point to your local postgresql database in the development
  and test sections and create the databases:

Make sure that the user specified in database.yml exists, and has full
permissions on these databases. As they need the ability to turn off
constraints whilst running the tests they also need to be a superuser.
If you don't want your database user to be a superuser, you can add a line
`disable_constraints: false` to the test config in database.yml, as seen in database.yml-example

You can create a `foi` user from the command line, thus:

    # su - postgres
    $ createuser -s -P foi

And you can create a database thus:

    $ createdb -T template0 -E SQL_ASCII -O foi foi_production
    $ createdb -T template0 -E SQL_ASCII -O foi foi_test
    $ createdb -T template0 -E SQL_ASCII -O foi foi_development

We create using the ``SQL_ASCII`` encoding, because in postgres this
is means "no encoding"; and because we handle and store all kinds of
data that may not be valid UTF (for example, data originating from
various broken email clients that's not 8-bit clean), it's safer to be
able to store *anything*, than reject data at runtime.

# Configure email

You will need to set up an email server (MTA) to send and receive
emails.  Full configuration for an MTA is beyond the scope of this
document, though we describe an example configuration for Exim in
`INSTALL-exim4.md`.

Note that in development mode, mail is handled by default by mailcatcher
so that you can see the mails in a browser - see http://mailcatcher.me/
for more details. Start mailcatcher by running `bundle exec mailcatcher`
in your application directory.

## Minimal

If you just want to get the tests to pass, you will at a minimum need
to allow sending emails via a `sendmail` command (a requirement met,
for example, with `sudo apt-get install exim4`).

## Detailed

When an authority receives an email, the email's `reply-to` field is a
magic address which is parsed and consumed by the Rails app.

To receive such email in a production setup, you will need to
configure your MTA to pipe incoming emails to the Alaveteli script
`script/mailin`. Therefore, you will need to configure your MTA to
accept emails to magic addresses, and to pipe such emails to this
script.

Magic email addresses are of the form:

    <foi+request-3-691c8388@example.com>

The respective parts of this address are controlled with options in
config/general.yml, thus:

    INCOMING_EMAIL_PREFIX = 'foi+'
    INCOMING_EMAIL_DOMAIN = 'example.com'

When you set up your MTA, note that if there is some error inside
Rails, the email is returned with an exit code 75, which for Exim at
least means the MTA will try again later.  Additionally, a stacktrace
is emailed to `CONTACT_EMAIL`.

`INSTALL-exim4.md` describes one possible configuration for Exim (>=
1.9).

A well-configured installation of this code will separately have had
Exim make a backup copy of the email in a separate mailbox, just in
case.

# Set up configs

Copy `config/general.yml-example` to `config/general.yml` and edit to
your taste.

Note that the default settings for frontpage examples are designed to
work with the dummy data shipped with Alaveteli; once you have real
data, you should certainly edit these.

The default theme is the "Alaveteli" theme.  When you run
`rails-post-deploy` (see below), that theme gets installed
automatically.

Finally, copy `config/newrelic.yml-example` to `config/newrelic.yml`.
This file contains configuration information for the New Relic
performance management system. By default, monitoring is switched off
by the `agent_enabled: false` setting. See https://github.com/newrelic/rpm
for instructions on switching on local and remote performance analysis.

# Deployment

In the 'alaveteli' directory, run:

    script/rails-post-deploy

(This will need execute privs so `chmod 755` if necessary.) This sets
up directory structures, creates logs, installs/updates themes, runs
database migrations, etc.  You should run it after each new software
update.

One of the things the script does is install dependencies (using
`bundle install`).  Note that the first time you run it, part of the
`bundle install` that compiles `xapian-full` takes a *long* time!

If you want some dummy data to play with, you can try loading the
fixtures that the test suite uses into your development database.  You
can do this with:

    script/load-sample-data

Next we need to create the index for the search engine (Xapian):

    script/rebuild-xapian-index

If this fails, the site should still mostly run, but it's a core
component so you should really try to get this working.

# Run the Tests

Make sure everything looks OK:

    bundle exec rake spec

If there are failures here, something has gone wrong with the
preceding steps (see the next section for a common problem and
workaround). You might be able to move on to the next step, depending
on how serious they are, but ideally you should try to find out what's
gone wrong.

## glibc bug workaround

There's a
[bug in glibc](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=637239)
which causes Xapian to segfault when running the tests.  Although the
bug report linked to claims it's fixed in the current Debian stable,
it's not as of version `2.11.3-2`.

Until it's fixed (e.g. `libc6 2.13-26` does work), you can get the
tests to pass by setting `export LD_PRELOAD=/lib/libuuid.so.1`.

# Run the Server

Run the following to get the server running:

    bundle exec rails server  --environment=development

By default the server listens on all interfaces. You can restrict it to the
localhost interface by adding ` --binding=127.0.0.1`

The server should have told you the URL to access in your browser to see
the site in action.

# Administrator privileges

The administrative interface is at the URL `/admin`.

Only users with the `super` admin level can access the admin
interface.  Users create their own accounts in the usual way, and then
administrators can give them `super` privileges.

There is an emergency user account which can be accessed via
`/admin?emergency=1`, using the credentials `ADMIN_USERNAME` and
`ADMIN_PASSWORD`, which are set in `general.yml`.  To bootstrap the
first `super` level accounts, you will need to log in as the emergency
user. You can disable the emergency user account by setting `DISABLE_EMERGENCY_USER` to `true` in `general.yml`.

Users with the superuser role also have extra privileges in the
website frontend, such as being able to categorise any request, being
able to view items that have been hidden from the search, and being
presented with "admin" links next to individual requests and comments
in the front end.

It is possible completely to override the administrator authentication
by setting `SKIP_ADMIN_AUTH` to `true` in `general.yml`.

# Cron jobs and init scripts

`config/crontab-example` contains the cronjobs run on WhatDoTheyKnow.
It's in a strange templating format they use in mySociety.  mySociety
render the example file to reference absolute paths, and then drop it
in `/etc/cron.d/` on the server.

The `ugly` format uses simple variable substitution.  A variable looks
like `!!(*= $this *)!!`.  The variables are:

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

There is a dumb python script at `script/make-crontab` which you can
edit and run to do some basic substitution for you.

One of the cron jobs refers to a script at
`/etc/init.d/foi-alert-tracks`.  This is an init script, a copy of
which lives in `config/alert-tracks-debian.ugly`.  As with the cron
jobs above, replace the variables (and/or bits near the variables)
with paths to your software. You can use the rake task `rake
config_files:convert_init_script` to do this.
`config/purge-varnish-debian.ugly` is a
similar init script, which is optional and not required if you choose
not to run your site behind Varnish (see below). Either tweak the file
permissions to make the scripts executable by your deploy user, or add the
following line to your sudoers file to allow these to be run by your deploy
user (named `deploy` in this case):

    deploy  ALL = NOPASSWD: /etc/init.d/foi-alert-tracks, /etc/init.d/foi-purge-varnish

The cron jobs refer to a program `run-with-lockfile`. See
[this issue](https://github.com/mysociety/alaveteli/issues/112) for a
discussion of where to find this program, and how you might replace
it. This [one line script](https://gist.github.com/3741194) can install
this program system-wide.

# Set up production web server

It is not recommended to run the website using the default Rails web
server.  There are various recommendations here:
http://rubyonrails.org/deploy

We usually use Passenger / mod_rails.  The file at `conf/httpd.conf-example`
gives you an example config file for WhatDoTheyKnow.  At a minimum, you should
include the following in an Apache configuration file:

    PassengerResolveSymlinksInDocumentRoot on
    PassengerMaxPoolSize 6 # Recommend setting this to 3 or less on servers with 512MB RAM

Under all but light loads, it is strongly recommended to run the
server behind an http accelerator like Varnish.  A sample varnish VCL
is supplied in `../conf/varnish-alaveteli.vcl`.

It's strongly recommended that you run the site over SSL. (Set FORCE_SSL to true in
config/general.yml). For this you will need an SSL certificate for your domain and you will
need to configure an SSL terminator to sit in front of Varnish. If you're already using Apache
as a web server you could simply use Apache as the SSL terminator. A minimal configuration
would look something like this:

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

Notice the line "RequestHeader" that sets the X-Forwarded-Proto header. This is important. This ultimately tells Rails that it's serving a page over https and so it knows to include that in any absolute urls it serves.

Some
[production server best practice notes](https://github.com/mysociety/alaveteli/wiki/Production-Server-Best-Practices)
are evolving on the wiki.

# Upgrading Alaveteli

The developer team policy is that the master branch in git should
always contain the latest stable release.  Therefore, in production,
you should usually have your software deployed from the master branch,
and an upgrade can be simply `git pull`.

Patch version increases (e.g. 1.2.3 -> 1.2.4) should not require any
further action on your part.

Minor version increases (e.g. 1.2.4 -> 1.3.0) will usually require
further action.  You should read the `CHANGES.md` document to see
what's changed since your last deployment, paying special attention to
anything in the "Updgrading" sections.

Any upgrade may include new translations strings, i.e. new or altered
messages to the user that need translating to your locale.  You should
visit Transifex and try to get your translation up to 100% on each new
release.  Failure to do so means that any new words added to the
Alaveteli source code will appear in your website in English by
default.  If your translations didn't make it to the latest release,
you will need to download the updated `app.po` for your locale from
Transifex and save it in the `locale/` folder.

You should always run the script `scripts/rails-post-deploy` after
each deployment.  This runs any database migrations for you, plus
various other things that can be automated for deployment.

# Troubleshooting

*   **Incoming emails aren't appearing in my Alaveteli install**

    First, you need to check that your MTA is delivering relevant
    incoming emails to the `script/mailin` command.  There are various
    ways of setting your MTA up to do this; we have documented one way
    of doing it in Exim at `doc/INSTALL-exim4.conf`, including a
    command you can use to check that the email routing is set up
    correctly.

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
    [https://github.com/mysociety/alaveteli/issues/128#issuecomment-1814845](this issue followup)
    for further discussion.

*   **I'm seeing `rake: command not found` when running the post install script

    The script uses `rake`.

    It may be that the binaries installed by bundler are not put in the
    system `PATH`; therefore, in order to run `rake` (needed for
    deployments), you may need to do something like:

        ln -s /usr/lib/ruby/gems/1.8/bin/rake /usr/local/bin/

