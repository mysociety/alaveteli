These instructions assume Debian Squeeze or Ubuntu 10.04 LTS.
[Install instructions for OS X](https://github.com/sebbacon/alaveteli/wiki/OS-X-Quickstart)
are under development.  Debian Squeeze is the best supported
deployment platform.

Commands are intended to be run via the terminal or over ssh.

As an aid to evaluation, there is an
[Amazon AMI](https://github.com/sebbacon/alaveteli/wiki/Alaveteli-ec2-amix)
with all these steps configured.  It is *not* production-ready.

# Get Alaveteli

To start with, you may need to install git, e.g. with `sudo apt-get
install git-core`

Next, get hold of the Alaveteli source code from github: 

    git clone https://github.com/datauy/alaveteli.git
    cd alaveteli

This will get the current stable release.  If you are a developer and want to
add or try new features, you might want to swap to the development
branch:

    git checkout develop

# If you want to use RVM then install it

    sh -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
    source ~/.bashrc
  
Check on requirements

    rvm requirements

Install 1.8.7 

    rvm install 1.8.7-head --with-openssl-dir=/usr/local

# Install system dependencies

These are packages that the software depends on: third-party software
used to parse documents, host the site, etc.  There are also packages
that contain headers necessary to compile some of the gem dependencies
in the next step.

If you are running Debian, you can use specially compiled mysociety
packages by adding the following to `/etc/apt/sources.list` and
running `apt-get update`:

    deb http://debian.mysociety.org squeeze main
    
If you are not using RVM:

Now install the packages that are listed in config/packages using apt-get
e.g.:

    sudo apt-get install `cut -d " " -f 1 config/packages | grep -v "^#"`

Some of the files also have a version number listed in config/packages
- check that you have appropriate versions installed. Some also list
"|" and offer a choice of packages.  If you've not set up the
mySociety Debian source (e.g. if you're running Ubuntu), you should
comment out `wkhtmltopdf-static` from `config/packages`, as it won't
install.

If you are using RVM:

You still need to install some packages but not ruby, ruby1.8, libopenssl-ruby1.8 or irb from config/packages. I recommend installing one by one to check if everything is fine.


DUDAS: gs-gpl es un dummy package, porque instalarlo?
       links, elinks ?
       php5-cli ??!
       mutt?

# Install Ruby dependencies

Install rubygems 1.6.1 (we're not using the Debian package because we
need an older version; see "Troubleshooting" below for an
explanation):

    wget http://rubyforge.org/frs/download.php/74445/rubygems-1.6.2.tgz -O /tmp/rubygems-1.6.2.tgz
    tar zxvf /tmp/rubygems-1.6.2.tgz -C /tmp/
    sudo ruby1.8 /tmp/rubygems-1.6.2/setup.rb
 
To install Alaveteli's Ruby dependencies, we also need to install
bundler:

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
[issue 305](https://github.com/sebbacon/alaveteli/issues/305))


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
(See http://dev.rubyonrails.org/ticket/9981)
  
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

You'll also want to copy `config/memcached.yml-example` to
`config/memcached.yml`. The application is configured, via the
Interlock Rails plugin, to cache content using memcached.  You
probably don't want this in your development profile; the example
`memcached.yml` file disables this behaviour.

# Deployment

In the 'alaveteli' directory, run:

    ./script/rails-post-deploy 

(This will need execute privs so `chmod 755` if necessary.) This sets
up directory structures, creates logs, installs/updates themes, runs
database migrations, etc.  You should run it after each new software
update.

One of the things the script does is install dependencies (using
`bundle install`).  Note that the first time you run it, part of the
`bundle install` that compiles `xapian-full` takes a *long* time!

On Debian, at least, the binaries installed by bundler are not put in
the system `PATH`; therefore, in order to run `rake` (needed for
deployments), you will need to do something like:

    ln -s /usr/lib/ruby/gems/1.8/bin/rake /usr/local/bin/
    
Or (Debian):

    ln -s /usr/lib/ruby/gems/1.8/bin/rake /usr/local/bin/


If you want some dummy data to play with, you can try loading the
fixtures that the test suite uses into your development database.  You
can do this with:

    ./script/load-sample-data

Next we need to create the index for the search engine (Xapian):

    ./script/rebuild-xapian-index

If this fails, the site should still mostly run, but it's a core
component so you should really try to get this working.

# Run the Tests

Make sure everything looks OK:

    rake spec

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

    ./script/server  --environment=development

By default the server listens on all interfaces. You can restrict it to the
localhost interface by adding ` --binding=127.0.0.1`

The server should have told you the URL to access in your browser to see
the site in action.

# Administrator privileges

By default, anyone can access the administrator pages without authentication.
They are under the URL `/admin`.

At mySociety (originators of the Alaveteli software), they use a
separate layer of HTTP basic authentication, proxied over HTTPS, to
check who is allowed to use the administrator pages. You might like to
do something similar.

Alternatively, update the code so that:

* By default, admin pages use normal site authentication (checking user admin
level 'super').
* Create an option in `config/general` which lets us override that
behaviour.

And send us the patch!


# Cron jobs

`config/crontab.ugly` contains the cronjobs run on WhatDoTheyKnow.
It's in a strange templating format they use in mySociety.  mySociety
render the "ugly" file to reference absolute paths, and then drop it
in `/etc/cron.d/` on the server.

The `ugly` format uses simple variable substitution.  A variable looks
like `!!(*= $this *)!!`.  The variables are:

* `vhost`: part of the path to the directory where the software is
  served from.  In the mySociety files, it usually comes as
  `/data/vhost/!!(*= $vhost *)!!` -- you should replace that whole
  port with a path to the directory where your Alaveteli software
  installation lives, e.g. `/var/www/`
* `vcspath`: the name of the alaveteli checkout, e.g. `alaveteli`.
  Thus, `/data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!` might be
  replaced with `/var/www/alaveteli` in your cron tab
* `user`: the user that the software runs as
* `site`: a string to identify your alaveteli instance

One of the cron jobs refers to a script at
`/etc/init.d/foi-alert-tracks`.  This is an init script, a copy of
which lives in `config/alert-tracks-debian.ugly`.  As with the cron
jobs above, replace the variables (and/or bits near the variables)
with paths to your software.

# Set up production web server

It is not recommended to run the website using the default Rails web
server.  There are various recommendations here:
http://rubyonrails.org/deploy

We usually use Passenger / mod_rails.  The file at `conf/httpd.conf`
contains the WhatDoTheyKnow settings.  At a minimum, you should
include the following in an Apache configuration file:

    PassengerResolveSymlinksInDocumentRoot on
    PassengerMaxPoolSize 6 # Recommend setting this to 3 or less on servers with 512MB RAM

Under all but light loads, it is strongly recommended to run the
server behind an http accelerator like Varnish.  A sample varnish VCL
is supplied in `../conf/varnish-alaveteli.vcl`.

Some
[production server best practice notes](https://github.com/sebbacon/alaveteli/wiki/Production-Server-Best-Practices)
are evolving on the wiki.

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
    [https://github.com/sebbacon/alaveteli/issues/128#issuecomment-1814845](this issue followup)
    for further discussion.
    
*   **I'm getting lots of `SourceIndex.new(hash) is deprecated` errors when running the tests**

    The latest versions of rubygems contain a large number of noisy
    deprecation warnings that you can't turn off individually.  Rails
    2.x isn't under active development so isn't going to get fixed (in
    the sense of using a non-deprecated API).  So the only vaguely
    sensible way to avoid this noisy output is to downgrade rubygems.
    
    For example, you might do this by uninstalling your
    system-packaged rubygems, and then installing the latest rubygems
    from source, and finally executing `sudo gem update --system
    1.6.2`.

