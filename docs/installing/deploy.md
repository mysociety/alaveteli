---
layout: page
title: Deploying
---

# Deploying Alaveteli

<p class="lead">
  Although you can install Alaveteli and just change it when you need it, we
  recommend you adopt a way of <strong>deploying</strong> it automatically,
  especially on your
  <a href="{{ site.baseurl }}docs/glossary/#production" class="glossary__link">production server</a>.
  Alaveteli provides a deployment mechanism using Capistrano.
</p>

## Why deploy?

Although you can [install Alaveteli]({{ site.baseurl }}docs/installing/) in a number
of ways, once you're running, sooner or later you'll need to make changes to
the site. A common example is updating your site when we issue a new release.

The deployment mechanism takes care of putting all the right files into the
right place, so when you need to put changes live, there's no risk of you
forgetting the update all the files you've changed, or breaking the
configuration by accident. Instead, deployment does all this for you
automatically. It's also more efficient because it is faster than making
changes or copying files by hand, so your site will be down for the shortest
possible time.

We **strongly recommend** you use the deployment mechanism for your
<a href="{{ site.baseurl }}docs/glossary/#production" class="glossary__link">production server</a>
and, if you're running one, your
<a href="{{ site.baseurl }}docs/glossary/#staging" class="glossary__link">staging server</a> too.

## Capistrano

<a href="{{site.baseurl}}docs/glossary/#capistrano" class="glossary__link">Capistrano</a>
is included as part of Alaveteli as a standard deployment system.

The basic principle of Capistrano is that you execute `cap [do-something]`
commands on your local machine, and Capistrano connects to your server (using
`ssh`) and does the corresponding task there for you.

### Set up

Capistrano requires things to be set up at both ends -- that is, on the server
where you want Alaveteli to run, and on your own local machine.

* *the server* is the machine that will be running the Alaveteli
  instance you're deploying

* your *local machine* may be your laptop or similar device -- as well as those
  belonging to anyone in your team whom you want to be able to deploy

In order to allow the Capistrano deployment mechanism work, you need to set up
the server so that the Alaveteli app is being served from a directory called
`current`. Once you've done that, deploying a new version is essentially
creating a timestamped sister directory to the `current` directory, and
switching the symlink `current` from the old timestamped directory to the new
one. Things that need to persist between deployments, like config files, are
kept in a `shared` directory that is at the same level, and symlinked-to from
each timestamped deploy directory.

We're [working on making this easier](https://github.com/mysociety/alaveteli/issues/1596),
but for now, here's the manual process you need to follow to set up this
deployment mechanism. Remember, you only have to do this once to set it up,
and thereafter you'll be able to deploy very easily (see [usage, below](#usage)).

First, on the server:

* [install Alaveteli]({{ site.baseurl }}docs/installing/)
* give the Unix user that runs Alaveteli the ability to ssh to your server. Either give them a password or, preferably, set up ssh keys for them so they can ssh from your local machine to the server:
   * to give them a password (if they don't already have one) - `sudo passwd [UNIX-USER]`. Store this password securely on your local machine e.g in a password manager
   * to set up ssh keys for them, follow the instructions in the [capistrano documentation](http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/). There's no need to set up ssh keys to the git repository as it is public.
* make sure the Unix user that runs Alaveteli has write permissions on the parent directory of your Alaveteli app
* move the Alaveteli app to a temporary place on the server, like your home
  directory (temporarily, your site will be missing, until the deployment puts
  new files in place)

Next, on your local machine:

* install Capistrano:
   * Capistrano requires Ruby 1.9 or more, and can be installed using rubygems
   * do: `gem install capistrano`
* install Bundler if you don't have it already -- do: `gem install bundler`
* checkout the [Alaveteli repo](https://github.com/mysociety/alaveteli/) (you
  need some of the files available locally even though you might not be running
  Alaveteli on this machine)
* copy the example file `config/deploy.yml.example` to `config/deploy.yml`
* now customise the deployment settings in that file: edit
  `config/deploy.yml` appropriately -- for example, edit the name of the
  server. Also, change `deploy_to` to be the path where Alaveteli is
  currently installed on the server -- if you used the installation
  script , this will be `/var/www/[HOST or alaveteli]/alaveteli`.
* `cd` into the Alaveteli repo you checked out (otherwise the `cap` commands you're about to
  execute won't work)
* still on your local machine, run `cap -S stage=staging deploy:setup` to setup capistrano on the server

If you get an error `SSH::AuthenticationFailed`, and are not prompted for the password of the deployment user, you may have run into [a bug](http://stackoverflow.com/questions/21560297/capistrano-sshauthenticationfailed-not-prompting-for-password) in the net-ssh gem version 2.8.0. Try installing version 2.7.0 instead:

    gem uninstall net-ssh

    gem install net-ssh -v 2.7.0

Back on the server:

* copy the following config files from the temporary copy of Alaveteli you made at
  the beginning (perhaps in your home directory) to the `shared` directory that
  Capistrano just created on the server:
   * `general.yml`
   * `database.yml`
   * `rails_env.rb`
   * `newrelic.yml`
   * `aliases` &larr; if you're using Exim as your MTA
* if you're using Exim as your MTA, edit the `aliases` file you just copied across
  so that the path to Alaveteli includes the `current` element. If it was
  `/var/www/alaveteli/alaveteli/script/mailin`, it should now be
  `/var/www/alaveteli/alaveteli/current/script/mailin`.
* copy the following directories from your temporary copy of Alaveteli to the
  `shared` directory created by Capistrano on the server:
   * `cache/`
   * `files/`
   * `lib/acts_as_xapian/xapiandbs` (copy this to straight into `shared` so it becomes `shared/xapiandbs`)
   * `log/`

Now, back on your local machine:

* make sure you're still in the Alaveteli repo (if not, `cd` back into it)
* run `cap -S stage=staging  deploy:update_code` to get a code checkout on the server.
* create a deployment directory on the server by running *one* of these commands:
   * `cap deploy` if you're deploying a <a href="{{site.baseurl}}docs/glossary/#staging" class="glossary__link">staging site</a>, or...
   * `cap -S stage=production deploy` for <a href="{{site.baseurl}}docs/glossary/#production" class="glossary__link">production</a>

Back on the server:

* update the webserver config (either apache or nginx) to add the `current` element
  to the path where it is serving Alaveteli from. If you installed using the
  installation script, this will be replacing `/var/www/alaveteli/alaveteli/` with
  `/var/www/alaveteli/alaveteli/current` in `/etc/nginx/sites-available/default`.
* edit the server crontab so that the paths in the cron jobs also include the
  `current` element. If you used the installation script the crontab will be in
  `etc/cron.d/alaveteli`.
* Update the MTA config to include the `current` element in the paths it uses.
  If you installed using the installation script, the MTA will be postfix,
  and you will need to edit  `/etc/postfix/master.cf` to replace
  `argv=/var/www/alaveteli/alaveteli/script/mailin` with
  `argv=/var/www/alaveteli/alaveteli/current/script/mailin`.
  If you're using Exim as your MTA, edit `etc/exim4/conf.d/04_alaveteli_options`
  to update the `ALAVETELI_HOME` variable to the new Alaveteli path. Restart the MTA after you've made these changes.

* You will also need to update the path to Alaveteli in your [init scripts]({{site.baseurl}}docs/installing/manual_install/#cron-jobs-and-init-scripts).
  You should have a script for running the alert tracks
  (`/etc/init.d/foi-alert-tracks`), and possibly scripts for purging the
  varnish cache (`/etc/init.d/foi-purge-varnish`), and restarting the
  app server (`/etc/init.d/alaveteli`).

Phew, you're done!

You can delete the temporary copy of Alaveteli (perhaps in your
home directory) now.

### Usage

Before you issue any Capistrano commands, `cd` into the checkout of the
Alaveteli repo on your local machine (because that's where it will look
for the config that you've set up).

Ensure you've got a `config/deploy.yml` file with the correct settings for your
site. If there are other people in your team who need to deploy, you'll need to
share it with them too -- it might be a good idea to keep the latest
version in a private [Gist](http://gist.github.com/).

* to deploy to staging, just run `cap deploy`
* to deploy to production, run `cap -S stage=production deploy`

You might notice that, after deploying, the old deploy directory is still there
-- that is, the one that was `current` until you replaced it with the new one.
By default, the deploy mechanism keeps the last five deployments there. Run
`cap deploy:cleanup` to tidy up older versions.

For additional usage instructions, see the [Capistrano
website](http://capistranorb.com/).

### Whoops, that's not what I expected

If a deployment goes wrong, or you discover after doing it that you're not
ready for the latest version after all, don't panic! Run `cap deploy:rollback`
and it will switch `current` back to the previous deployment.

