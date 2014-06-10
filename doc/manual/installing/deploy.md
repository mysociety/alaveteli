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

Although you can install Alaveteli in a number of ways, once you're running,
sooner or later you'll need to make changes to the site. A common example is
updating your site when we issue a new release.

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

Capistrano is included as part of Alaveteli as a standard deployment system.

### Set up

First you need to customise your deployment settings, for example the name of the
server you're deploying to. Copy the example file `config/deploy.yml.example` to
`config/deploy.yml` and edit the settings to
suit you.

These are the general steps required to set up the deployment mechanism. Capistrano
requires things to be set up at both ends -- that is, on the server where you want
Alaveteli to run, and on your own machine (and on the machines of anyone in your team
who you want to be able to deploy):

* Install packages from `config/packages`
* Install Postgres and configure a user
* Create a directory to deploy to and make sure your deployment user can write to it
* Run `cap deploy:setup` to create directories, etc.
* Run `cap deploy:update_code` so that we've got a copy of the example config on the server. This process will take a long time installing gems, etc. it will also fail on `rake:themes:install` but that's OK
* SSH to the server, change to the `deploy_to` directory
* `cp releases/[SOME_DATE]/config/general.yml-example shared/general.yml`
* `cp releases/[SOME_DATE]/config/database.yml-example shared/database.yml`
* Edit those files to match your required settings
* Back on your machine run `cap deploy` and it should successfully deploy
* Run the DB migrations `cap deploy:migrate`
* Build the Xapian DB `cap xapian:rebuild_index`
* Configure Apache/Passenger with a DocumentRoot of `your_deploy_to/current/public`
* Phew. Time to admire your work by browsing to the server!


### Usage

Ensure you've got a `config/deploy.yml` file with the correct settings for your
site. You'll need to share this with everyone in your team that deploys so it
might be a good idea to keep the latest version in a
[Gist](http://gist.github.com/).

To deploy to staging just run `cap deploy` but if you want to deploy to
production you need to run `cap -S stage=production deploy`.

For additional usage instructions, see the [Capistrano
wiki](https://github.com/capistrano/capistrano/wiki/).

