These instructions assume Debian Squeeze or Ubuntu 11.04, or later
(probably, though we won't necessarily have tested in later versions
yet!)
[Install instructions for OS X](https://github.com/sebbacon/alaveteli/wiki/OS-X-Quickstart)
are under development.

It is possible to install on Ubuntus as old as 10.04, but you must use
[Xapian backports](https://launchpad.net/~xapian-backports/+archive/xapian-1.2)
(see [issue #158](https://github.com/sebbacon/alaveteli/issues/159)
for discussion).

Commands are intended to be run via the terminal or over ssh.

As an aid to evaluation, there is an Amazon AMI with all these steps
configured.  Its id is ami-fa52a993.  It is *not* production-ready:
Apache isn't set up, and the passwords are insecure.  You may wish to
run a `git pull` in the source on the software, as it is unlikely to
be up to date.

# Package Installation

First, get hold of the source code from github: 

    git clone https://github.com/sebbacon/alaveteli.git

(You may need to install git first, e.g. with `sudo apt-get install git-core`)

Now, in a terminal, navigate to the alaveteli folder where this
install guide lives.

Install the packages that are listed in config/packages using apt-get e.g.:

    sudo apt-get install `cut -d " " -f 1 config/packages | grep -v "^#"`

Some of the files also have a version number listed in config/packages - check
that you have appropriate versions installed. Some also list "|" and offer
a choice of packages.


You will also want to install mySociety's common ruby libraries and the Rails
code. Run:

    git submodule update --init

to fetch the contents of the submodules.

If you would like users to be able to download pretty PDFs as part of 
the downloadable zipfile of their request history, you should also install
[wkhtmltopdf](http://code.google.com/p/wkhtmltopdf/downloads/list).  
We recommend downloading the latest, statically compiled version from
the project website, as this allows running headless (i.e. without a
graphical interface running) on Linux.  If you do install
`wkhtmltopdf`, you need to edit a setting in the config file to point
to it (see below).  If you don't install it, everything will still work, but 
users will get ugly, plain text versions of their requests when they 
download them.

Version 1.44 of `pdftk` contains a bug which makes it to loop forever
in certain edge conditions.  Until it's incorporated into an official
release, you can either hope you don't encounter the bug (it ties up a
rails process until you kill it) you'll need to patch it yourself or
use the Debian package compiled by mySociety (see link in
[issue 305](https://github.com/sebbacon/alaveteli/issues/305))

# Configure Database 

There has been a little work done in trying to make the code work with
other databases (e.g. SQLite), but the preferred database is PostgreSQL.

If you don't have it installed:

    apt-get install postgresql postgresql-client

Now we need to set up the database config file to contain the name,
username and password of your postgres database.

* copy `database.yml-example` to `database.yml` in `alaveteli/config`
* edit it to point to your local postgresql database in the development
  and test sections and create the databases:

Become the 'postgres' user (`sudo su - postgres`)

Make sure that the user specified in database.yml exists, and has full
permissions on these databases. As they need the ability to turn off
constraints whilst running the tests they also need to be a superuser.
  (See http://dev.rubyonrails.org/ticket/9981)

The following command will set up a user 'foi' with password 'foi':

    echo "CREATE DATABASE foi_development encoding 'SQL_ASCII' template template0;
    CREATE DATABASE foi_test encoding 'SQL_ASCII' template template0;
    CREATE USER foi WITH CREATEUSER;
    ALTER USER foi WITH PASSWORD 'foi';
    ALTER USER foi WITH CREATEDB;
    GRANT ALL PRIVILEGES ON DATABASE foi_development TO foi;
    GRANT ALL PRIVILEGES ON DATABASE foi_test TO foi;    	
    ALTER DATABASE foi_development OWNER TO foi;
    ALTER DATABASE foi_test OWNER TO foi;" | psql
    
We create using the ``SQL_ASCII`` encoding, because in postgres this
is means "no encoding"; and because we handle and store all kinds of
data that may not be valid UTF (for example, data originating from
various broken email clients that's not 8-bit clean), it's safer to be
able to store *anything*, than reject data at runtime.

# Configure email

You will need to set up an email server (MTA) to send and receive
emails.  Full configuration for an MTA is beyond the scope of this
document. However, just to get the tests to pass, you will at a
minimum need to allow sending emails via a `sendmail` command (a
requirement met, for example, with `sudo apt-get install exim4`).

To receive email in a production setup, you will also need to
configure your MTA to forward incoming emails to Alaveteli.  An
example configuration is described in `INSTALL-exim4.md`.

# Set up configs

For overall application settings, copy `config/general.yml-example` to
`config/general.yml` and edit to your taste.

Note that the default settings for frontpage examples are designed to
work with the dummy data shipped with Alaveteli; once you have real
data, you should edit these.

The default theme is the "WhatDoTheyKnow" theme.  When you run
`rails-post-deploy` (see below), that theme gets installed automatically.

You'll also want to copy `config/memcached.yml-example` to
`config/memcached.yml`. The application is configured, via the
Interlock Rails plugin, to cache content using memcached.  You
probably don't want this in your development profile; the example
`memcached.yml` file disables this behaviour.

# Deployment

In the 'alaveteli' directory, run:

    ./script/rails-post-deploy 

(This will need execute privs so `chmod 755` if necessary)

This sets up directory structures, creates logs, etc.

Next, if you have a `alaveteli/config/rails_env.rb` file, delete it,
so that tests run against our test database, rather than the
development one.  (Otherwise, any data you create in development will
be blown away every time you run the tests.)

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

If there are failures here, something has gone wrong with the preceding
steps. You might be able to move on to the next step, depending on how
serious they are, but ideally you should try to find out what's gone
wrong.

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

# Mailer setup

When an authority receives an email, the email's `reply-to` field is a
magic address which is parsed and consumed by the Rails app.

Currently, this is done by calling `script/mailin` and piping in the raw
email.  You will need to configure your MTA to accept emails to magic
addresses, and to pipe such emails to this script.

Magic email addresses are of the form:

    <foi+request-3-691c8388@example.com>

The respective parts of this address are controlled with options in
options/general, thus:

    $OPTION_INCOMING_EMAIL_PREFIX = 'foi+'
    $OPTION_INCOMING_EMAIL_DOMAIN = 'example.com'

`INSTALL-exim.txt` describes one possible configuration for Exim (>=
1.9).

When you set up your MTA, note that if there is some error inside
Rails, the email is returned with an exit code 75, which for Exim at
least means the MTA will try again later.  Additionally, a stacktrace
is emailed to `$OPTION_CONTACT_EMAIL`.

A well-configured installation of this code will separately have had
Exim make a backup copy of the email in a separate mailbox, just in
case.

This setup isn't very scaleable, as it spawns a new Ruby process for
each email received; patches welcome!

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

    Did you remember to remove the file `alaveteli/config/rails_env.rb`
    as described above?  It's created every time you run
    `script/rails-post-deploy`

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

