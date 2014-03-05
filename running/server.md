---
layout: page
title: Production server best prctices
---

# Production server best prctices

<p class="lead">
  This list of notes serve as a checklist to make sure you're running
  your production server sensibly. Of course you should refer to this
  list before you've gone live.
</p>


## Hosting options
* Cloud Server
* Virtual Private Server

## Cron jobs

Don't forget to set up the cron jobs as outlined in the
[installation instructions]({{ site.baseurl }}installing/manual_install). 
As of October 2011, they rely on a small program created by mySociety called
`run-with-lockfile`. A discussion of where the source for this can be found,
and possible alternatives, lives in
[this ticket](https://github.com/mysociety/alaveteli/issues/112).

## Webserver configuration

We recommend running your site behind Apache + Passenger. Refer to the 
[installation instructions]({{ site.baseurl }}installing/manual_install)
regarding `PassengerMaxPoolSize`, which you should
experiment with to match your available RAM. It is very unlikely that you'll
ever need a pool larger than [Passenger's
default](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_pass
engermaxpoolsize_lt_integer_gt) of 6.

We recommended you run your server behind an HTTP accelerator like Varnish.
Alaveteli ships with a 
[sample varnish VCL](https://github.com/mysociety/alaveteli/blob/master/config/varnish-alav
eteli.vcl).

## Security

You must change all key-related [config settings]({{ site.baseurl }}customising/config)
in `general.yml` from their default values. This includes (but may not be limited to!):

* `INCOMING_EMAIL_SECRET`
* `ADMIN_USERNAME`
* `ADMIN_PASSWORD`
* `COOKIE_STORE_SESSION_SECRET`
* `RECAPTCHA_PUBLIC_KEY`
* `RECAPTCHA_PRIVATE_KEY`

You should consider running the admin part of the site over HTTPS. This can be
achieved with rewrite rules that redirect URLs beginning with `/admin`.

## Email configuration

See the application-specific 
[email configuration for exim]({{ site.baseurl }}installing/exim4) for
setting up your Mail Transfer Agent (MTA). It is possible to use other MTAs;
the documentation for exim should provide you with enough information to get
started with a different MTA. If you do use a different one, please add to the
documentation!

On a live server, you should also consider the following, to increase the
deliverability of your email:

* Set up [SPF records](http://www.openspf.org/) for your domain
* Set up <a
  href="http://en.wikipedia.org/wiki/Feedback_loop_(email)#Feedback_loop_links_f
  or_some_email_providers">feedback loops</a> with the main email providers
  (Hotmail and Yahoo! are recommended)
* Especially if deploying from Amazon EC2, use an external SMTP relay for
  sending outgoing mail. See [Alaveteli EC2 AMI]( {{ site.baseurl }}installing/ami)
  for more suggestions.

## Backup

Most of the data for the site lives in the production database. The exception
is the raw incoming email data, which is stored on the filesystem, as specified
in the setting `RAW_EMAILS_LOCATION` of `config/general.yml`.

Refer to the [Postgres
documentation](http://www.postgresql.org/docs/8.4/static/backup.html) for
database backup strategies. The most common method is to use `pg_dump` to
create a SQL dump of the database, and backup a zipped copy of this.

Raw emails would be best backed up using an incremental strategy.
[Rsync](http://rsync.samba.org/) is one way of doing this.

Another belt-and-braces backup strategy is to set up your MTA to copy all
incoming and outgoing mail to a backup mailbox. One way of doing this with exim
is to put the following in your exim config:

    system_filter = ALAVETELI_HOME/config/exim.filter
    system_filter_user = ALAVETELI_USER

And then create a filter file at `ALAVETELI_HOME/config/exim.filter`, with
something like:

    if error_message then finish endif
    if $header_to: contains "mydomain.org"
    then
    unseen deliver "backup@mybackupdomain.org"
    endif 

    if $sender_address: contains "mydomain.org"
    then
    unseen deliver "backup@mybackupdomain.org"
    endif

