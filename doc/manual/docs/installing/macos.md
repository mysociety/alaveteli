---
layout: page
title: Installing on MacOS X
---

# Installation on MacOS X

<p class="lead">
  We don't recommend using OS X in production, but if you want to get
  Alaveteli running on your Mac for development, these guidelines should
  help.
</p>

Note that there are [other ways to install Alaveteli]({{ site.baseurl }}docs/installing/).

## MacOS X 10.7

Follow these instructions to get Alaveteli running locally on an OS X machine. These instructions have been tested with Xcode 4.1 on OS X Lion (10.7). We do not recommend using OS X in production.

**Note:** This guide is currently incomplete. Please help by posting issues to the [alaveteli-dev Google group](https://groups.google.com/group/alaveteli-dev) or by submitting pull requests.

## Xcode

If you are using OS X Lion, download *Command Line Tools for Xcode* from [Apple](https://developer.apple.com/downloads/index.action). This is a new package from Apple that provides the command-line build tools separate from the rest of Xcode. You need to register for a free Apple Developer account.

**Note:** As of Xcode 4.2, a non-LLVM version of GCC is no longer included. Homebrew has dealt with it by [switching to Clang](https://github.com/mxcl/homebrew/issues/6852). However, you may encounter errors installing RVM. *Please report these on the [mailing list](https://groups.google.com/group/alaveteli-dev).* The following instructions have been tested with Xcode 4.1. If necessary, you can install GCC from Xcode 4.1 by running:

    brew install https://github.com/adamv/homebrew-alt/raw/master/duplicates/apple-gcc42.rb

## Homebrew

Homebrew is a package manager for OS X. It is preferred over alternatives such as MacPorts and Fink. If you haven't already installed Homebrew, run the command:

    ruby <(curl -fsSkL raw.github.com/mxcl/homebrew/go)

Next, install packages required by Alaveteli:

    brew install catdoc elinks gnuplot gs imagemagick libmagic libyaml links mutt poppler tnef wkhtmltopdf wv xapian unrtf


### Install postgresql

Alaveteli uses PostgreSQL by default. If you've tested Alaveteli with MySQL or SQLite, let us know in the [alaveteli-dev Google group](https://groups.google.com/group/alaveteli-dev).

    brew install postgresql
    initdb /usr/local/var/postgres
    mkdir -p ~/Library/LaunchAgents
    cp /usr/local/Cellar/postgresql/9.0.4/org.postgresql.postgres.plist ~/Library/LaunchAgents/
    launchctl load -w ~/Library/LaunchAgents/org.postgresql.postgres.plist

## PDF Toolkit

[Download the installer package](https://github.com/downloads/robinhouston/pdftk/pdftk.pkg) and install.

## Ruby

### Install RVM

RVM is the preferred way to install multiple Ruby versions on OS X. Alaveteli uses Ruby 1.8.7. The following commands assume you are using the Bash shell.

    curl -L https://get.rvm.io | bash -s stable

Read `rvm notes` and `rvm requirements` carefully for further instructions. Then, install Ruby:

    rvm install 1.8.7
    rvm install 1.9.3
    rvm use 1.9.3 --default

### Install mahoro and pg with flags

The `mahoro` and `pg` gems require special installation commands. Rubygems must be downgraded to 1.6.2 to avoid deprecation warnings when running tests.

    rvm 1.8.7
    gem update --system 1.6.2
    gem install mahoro -- --with-ldflags="-L/usr/local/Cellar/libmagic/5.09/lib" --with-cppflags="-I/usr/local/Cellar/libmagic/5.09/include"
    env ARCHFLAGS="-arch x86_64" gem install pg

#### Update

As of August 22, 2012 or earlier, you can install `mahoro` in Ruby 1.9.3 on OS X 10.7 Lion with:

    brew install libmagic
    gem install mahoro

## Alaveteli

The following is mostly from [the manual installation process]({{ site.baseurl}}docs/installing/manual_install).

### Configure database

Create a database for your Mac user as homebrew doesn't create one by default:

    createdb

Create a `foi` user from the command line, like this:

    createuser -s -P foi

_Note:_ Leaving the password blank will cause great confusion if you're new to
PostgreSQL.

We'll create a template for our Alaveteli databases:

    createdb -T template0 -E UTF-8 template_utf8
    echo "update pg_database set datistemplate=true where datname='template_utf8';" | psql

Then create the databases:

    createdb -T template_utf8 -O foi alaveteli_production
    createdb -T template_utf8 -O foi alaveteli_test
    createdb -T template_utf8 -O foi alaveteli_development

### Clone Alaveteli

    git clone https://github.com/mysociety/alaveteli.git
    cd alaveteli
    git submodule init
    git submodule update


### Configure Alaveteli

Copy the example configuration files and configure `database.yml`.

    cp -f config/general.yml-example config/general.yml
    cp -f config/memcached.yml-example config/memcached.yml
    cp -f config/database.yml-example config/database.yml
    sed -i~ 's/<username>/foi/' config/database.yml
    sed -i~ 's/<password>/foi/' config/database.yml
    sed -i~ 's/  port: 5432//' config/database.yml
    sed -i~ 's/ # PostgreSQL 8.1 pretty please//' config/database.yml

### Bundler

Install the gems and finish setting up Alaveteli.

    rvm 1.8.7
    bundle
    bundle exec rake db:create:all
    bundle exec rake db:migrate
    bundle exec rake db:test:prepare

## Troubleshooting

### Ruby version

Ensure you are using the latest versions of Ruby. For example, some versions of Ruby 1.8.7 will segmentation fault, for example:

```
/Users/james/.rvm/gems/ruby-1.8.7-p357/gems/json-1.5.4/ext/json/ext/json/ext/parser.bundle: [BUG] Segmentation fault
ruby 1.8.7 (2011-12-28 patchlevel 357) [i686-darwin11.3.0]
```

Running `rvm install 1.8.7` should install the latest Ruby 1.8.7 patch level. Remember to switch to the new Ruby version before continuing.

### Rake tasks

Remember to run Rake tasks with `bundle exec`. To run the tests, for example, run `bundle exec rake`.
