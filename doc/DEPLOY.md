# Deployment

mySociety uses a custom deployment and buildout system however Capistrano is included as part of Alaveteli as a standard deployment system.

## Capistrano

### Set up

First you need to customise your deployment settings, e.g. the name of the server you're deploying to. This is done by copying the example file `config/deploy.yml.example` to `config/deploy.yml` and editing the settings to suit you.

TODO: The following instructions could be greatly improved

These are the general steps required to get your staging server up and running:

* Install packages from `config/packages`
* Install Postgres and configure a user
* Create a directory to deploy to and make sure your deployment user can write to it
* Run `cap deploy:setup` to create directories, etc.
* Run `cap deploy:update_code` so that we've got a copy of the example config on the server. This process will take a long time installing gems, etc. it will also fail on `rake:themes:install` but that's OK
* SSH to the server, change to the `deploy_to` directory
* `cp releases/[SOME_DATE]/config/general.yml-example shared/general.yml`
* `cp releases/[SOME_DATE]/config/database.yml-example shared/database.yml`
* `cp releases/[SOME_DATE]/config/memcached.yml-example shared/memcached.yml`
* Edit those files to match your required settings
* Back on your machine run `cap deploy` and it should successfully deploy
* Run the DB migrations `cap deploy:migrate`
* Build the Xapian DB `cap xapian:rebuild_index`
* Configure Apache/Passenger with a DocumentRoot of `your_deploy_to/current/public`
* Phew. Time to admire your work by browsing to the server!

### Usage

Ensure you've got a `config/deploy.yml` file with the correct settings for your site. You'll need to share this with everyone in your team that deploys so it might be a good idea to keep the latest version in a [Gist](http://gist.github.com/).

To deploy to staging just run `cap deploy` but if you want to deploy to production you need to run `cap -S stage=production deploy`.

For additional usage instructions, see the [Capistrano wiki](https://github.com/capistrano/capistrano/wiki/).

### TODO

* Get `cap deploy:setup` to do most of the work described above in the *Set up* section
* Use [Whenever](https://github.com/javan/whenever) to set up cronjobs
