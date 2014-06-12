---
layout: page
title: Deploying
---

# Deploying Alaveteli

<p class="lead">
  Although you can install Alaveteli and just change it when you need it, we
  recommend you adopt a way of <strong>deploying</strong> it automatically,
  especially on your <a href="{{ site.baseurl }}glossary/#production">production server</a>.
  Alaveteli provides a deployment mechanism using Capistrano.
</p>

## Why deploy?

Although you can [install Alaveteli]({{ site.baseurl }}installing/) in a number
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
<a href="{{ site.baseurl }}glossary/#production">production server</a> and, if
you're running one, your 
<a href="{{ site.baseurl }}glossary/#staging">staging server</a> too.

## Capistrano

<a href="{{site.baseurl}}glossary/#capistrano" class="glossary">Capistrano</a>
is included as part of Alaveteli as a standard deployment system.

### Set up

Capistrano requires things to be set up at both ends -- that is, on the server
where you want Alaveteli to run, and on your own local machine.

* your *local machine* may be your laptop or similar device -- as well as those
  belonging to anyone in your team whom you want to be able to deploy
* *the server* is the machine (possibly on that will be running the Alaveteli instance you're deploying

First you need to customise the deployment settings on your own machine. Copy
the example file `config/deploy.yml.example` to `config/deploy.yml` and edit
the settings to suit -- for example, the name of the server.

These are the general steps required to set up the deployment mechanism:

On your local machine:

* Install packages from `config/packages`
* Install Postgres and configure a user
* Create a directory to deploy to and make sure your deployment user can write to it
* Run `cap deploy:setup` to create directories, etc.
* Run `cap deploy:update_code` so that there's a copy of the example config on the server.
  This process will take a long time installing gems and suchlike.
  It will also fail on `rake:themes:install` -- but that's OK

Next, on the server:

> *Note:* if you've *already* installed Alaveteli, these files may already be in place.
> Otherwise, you should [install Alaveteli]({{ site.baseurl }}installing/) first.

* change to the `deploy_to` directory
* `cp releases/[SOME_DATE]/config/general.yml-example shared/general.yml`
* `cp releases/[SOME_DATE]/config/database.yml-example shared/database.yml`
* Edit those files to match your required settings

Then, back on your local machine:

* Back on your machine, run `cap deploy` and it should successfully deploy
* Do the DB migrations: run `cap deploy:migrate`
* Build the Xapian database: run `cap xapian:rebuild_index`
* Configure Apache/Passenger with a `DocumentRoot` of `your_deploy_to/current/public`
* Phew. Time to admire your work by browsing to the server!


### Usage

Ensure you've got a `config/deploy.yml` file with the correct settings for your
site. If there are other people in your team who need to deploy, you'll need to
share it with them too -- it might be a good idea to keep the latest
version in a [Gist](http://gist.github.com/).

* to deploy to staging, just run `cap deploy`
* to deploy to production, run `cap -S stage=production deploy`

For additional usage instructions, see the [Capistrano
wiki](https://github.com/capistrano/capistrano/wiki/).

