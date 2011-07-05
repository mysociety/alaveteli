These instructions are based on getting the FOI site up and running on
Ubuntu and/or Debian.

It was last run using the Lucid Lynx version of Ubuntu and on the
Parallels debian instance (2.6.18-4-686).

Commands are intended to be run via the terminal or over ssh.

As an aid to evaluation, there is an Amazon AMI with all these steps
configured.  Its id is ami-fa52a993.  It is *not* production-ready:
Apache isn't set up, and the passwords are insecure.  You may wish to
run a `git pull` in the source on the software, as it is unlikely to
be up to date.

# Package Installation

First, get hold of the source code from github: 

    git clone https://github.com/sebbacon/alaveteli.git

(You may need to install git first, e.g. with `sudo apt-get install git-code`)

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

    echo "CREATE DATABASE foi_development encoding = 'UTF8';
    CREATE DATABASE foi_test encoding = 'UTF8';
    CREATE USER foi WITH CREATEUSER;
    ALTER USER foi WITH PASSWORD 'foi';
    ALTER USER foi WITH CREATEDB;
    GRANT ALL PRIVILEGES ON DATABASE foi_development TO foi;
    GRANT ALL PRIVILEGES ON DATABASE foi_test TO foi;    	
    ALTER DATABASE foi_development OWNER TO foi;
    ALTER DATABASE foi_test OWNER TO foi;" | psql

# Set up configs

For overall application settings, copy `config/general-example` to
`config/general` and edit to your taste.

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

    rake spec:db:fixtures:load

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

`config/crontab.ugly` contains the cronjobs run on WhatDoTheyKnow.  It's
in a strange templating format they use in mySociety, but you should be
able to work out the syntax and variables fairly easily :)

mySociety render the "ugly" file to reference absolute paths, and then
drop it in /etc/cron.d/ on the server.

# Troubleshooting

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
