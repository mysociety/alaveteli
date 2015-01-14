---
layout: page
title: Production server best practices
---

# Production server best practices

<p class="lead">
  These notes serve as a checklist of things to consider when you're ready
  to deploy your Alaveteli site to production.
</p>


## Hosting options

Your production server must be reliable and secure. If you don't run your own
servers already, consider one of these options:

* Cloud Server
* Virtual Private Server

In some cases, we can host new Alaveteli projects &mdash; if you need help,
ask us about hosting.

## Cron jobs

Don't forget to set up the cron jobs as outlined in the
[installation instructions]({{ page.baseurl }}/docs/installing/manual_install/).

## Webserver configuration

We recommend running your site behind
[Apache](https://httpd.apache.org) +
[Passenger](https://www.phusionpassenger.com) or [Nginx](http://wiki.nginx.org/Main) + [Thin](http://code.macournoyer.com/thin/).

If you're using Passenger, refer to the
[installation instructions]({{ page.baseurl }}/docs/installing/manual_install/)
regarding `PassengerMaxPoolSize`, which you should
experiment with to match your available RAM. It is very unlikely that you'll
ever need a pool larger than [Passenger's
default](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_passengermaxpoolsize_lt_integer_gt) of 6.

We recommend you run your server behind an HTTP accelerator like
[Varnish](https://www.varnish-cache.org).
Alaveteli ships with a
[sample varnish VCL](https://github.com/mysociety/alaveteli/blob/master/config/varnish-alaveteli.vcl).

## Security

You _must_ change all key-related [config settings]({{ page.baseurl }}/docs/customising/config/)
in `general.yml` from their default values. This includes (but may not be limited to!)
these settings:

* [`INCOMING_EMAIL_SECRET`]({{ page.baseurl }}/docs/customising/config/#incoming_email_secret)
* [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
* [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password)
* [`COOKIE_STORE_SESSION_SECRET`]({{ page.baseurl }}/docs/customising/config/#cookie_store_session_secret)
* [`RECAPTCHA_PUBLIC_KEY`]({{ page.baseurl }}/docs/customising/config/#recaptcha_public_key)
* [`RECAPTCHA_PRIVATE_KEY`]({{ page.baseurl }}/docs/customising/config/#recaptcha_private_key)

You should consider running the admin part of the site over HTTPS. This can be
achieved with rewrite rules that redirect URLs beginning with `/admin`.

## Email configuration

See the [configuration for exim or postfix]({{ page.baseurl }}/docs/installing/email/) for
setting up your Mail Transfer Agent (MTA). It is possible to use other MTAs &mdash;
if you use a different one, the documentation there should provide you with
enough information to get started. If this applies to you, please add to the
documentation!

On a live server, you should also consider the following, to increase the
deliverability of your email:

* Set up [SPF records](http://www.openspf.org/) for your domain
* Set up <a
  href="http://wiki.asrg.sp.am/wiki/Feedback_loop_links_for_some_email_providers">feedback loops</a> with the main email providers
  (Hotmail and Yahoo! are recommended)
* Especially if deploying from Amazon EC2, use an external SMTP relay for
  sending outgoing mail. See [Alaveteli EC2 AMI]( {{ page.baseurl }}/docs/installing/ami/)
  for more suggestions.

## Backup

Most of the data for the site lives in the production database. The exception
is the raw incoming email data, which is stored on the filesystem, as specified
in the setting
[`RAW_EMAILS_LOCATION`]({{ page.baseurl }}/docs/customising/config/#raw_emails_location)
setting in `config/general.yml`.

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

