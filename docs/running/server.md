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
[Passenger](https://www.phusionpassenger.com), or behind [Nginx](https://nginx.org) as a reverse proxy in front of [Puma](https://puma.io) (the application server Alaveteli bundles).

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

If your hosting company supports [IPv6](https://en.wikipedia.org/wiki/IPv6)
make sure that you've enabled this and configured [an AAAA record](https://en.wikipedia.org/wiki/List_of_DNS_record_types#AAAA)
in your domain's DNS zone for capable clients.

## Search engines and crawling

Most of what an Alaveteli site holds is only worth publishing if people can
find it, and for most sites that means search engines.

### What Alaveteli keeps out of search results

Alaveteli ships a `robots.txt` which keeps crawlers away from pages that are
expensive to generate or not worth indexing, such as search results, feeds and
the forms for making a request. It is rendered from
`app/views/robots/show.text.erb`, so you can
[override it in your theme]({{ page.baseurl }}/docs/customising/themes/) like
any other template rather than editing Alaveteli's copy.

Two other rules apply automatically:

* every page of a listing after the first is served with an
  `X-Robots-Tag: noindex, nofollow` header, because later pages are expensive
  and their contents appear elsewhere
* requests set to the `backpage`
  [prominence]({{ page.baseurl }}/docs/running/hiding_information/) are served
  with the same header, which is what that prominence is for

### Publishing a sitemap

Because listings are capped and only their first page is indexable, a crawler
which just follows links will reach very few of your requests. A
[sitemap](https://www.sitemaps.org/) is what makes the rest of the archive
discoverable, so it is enabled by default. Set
<code><a href="{{ page.baseurl }}/docs/customising/config/#enable_sitemap">ENABLE_SITEMAP</a></code>
to `false` if you would rather your site was not indexed.

The sitemap covers the requests Alaveteli already treats as searchable, every
visible authority, and the site's main static pages. Requests which are hidden,
requester-only, embargoed or on the backpage are not listed.

It is built ahead of time rather than when it is requested, by a nightly cron
job:

    bin/rails sitemap:generate

Install the `sitemap:generate` entry from `config/crontab-example` along with
the rest of your cron jobs. Until it has run for the first time, `/sitemap.xml`
will return a 404.

The generated files are written to the `cache/` directory, which should be one
of your `SHARED_DIRECTORIES` so that they survive a deploy. A large site
produces a sitemap index plus one gzipped file per 50,000 URLs.

### Telling search engines about it

`robots.txt` advertises the sitemap automatically, which is all most crawlers
need. You can also submit it directly through
[Google Search Console](https://search.google.com/search-console) or
[Bing Webmaster Tools](https://www.bing.com/webmasters), which additionally
report any problems found in it.

There is no need to notify search engines when the sitemap changes. The old
"ping" endpoints for doing so have been withdrawn by both
[Google](https://developers.google.com/search/blog/2023/06/sitemaps-lastmod-ping)
and Bing, which is why Alaveteli does not call them.

## Security

You _must_ change all key-related [config settings]({{ page.baseurl }}/docs/customising/config/)
in `general.yml` from their default values. This includes (but may not be limited to!)
these settings:

* [`INCOMING_EMAIL_SECRET`]({{ page.baseurl }}/docs/customising/config/#incoming_email_secret)
* [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
* [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password)
* [`SECRET_KEY_BASE`]({{ page.baseurl }}/docs/customising/config/#secret_key_base)
* [`RECAPTCHA_SITE_KEY`]({{ page.baseurl }}/docs/customising/config/#recaptcha_site_key)
* [`RECAPTCHA_SECRET_KEY`]({{ page.baseurl }}/docs/customising/config/#recaptcha_secret_key)

You should consider running the admin part of the site over HTTPS. This can be
achieved with rewrite rules that redirect URLs beginning with `/admin`.

Additionally, the `INCOMING_EMAIL_DOMAIN` should not be the one that you use for your organisational email.
Mail sent to Alaveteli request addresses is published on the site, and using an organisational email domain
could leave you vulnerable to attacks that sign up for your internal tools using these addresses and use
Alaveteli to receive and publish confirmation emails. Use a completely different domain or a subdomain
of your organisational domain. See [this blog post](https://medium.freecodecamp.org/how-i-hacked-hundreds-of-companies-through-their-helpdesk-b7680ddc2d4c) for a description of this kind of
attack.

## Email configuration

See the [configuration for exim or postfix]({{ page.baseurl }}/docs/installing/email/) for
setting up your Mail Transfer Agent (MTA). It is possible to use other MTAs &mdash;
if you use a different one, the documentation there should provide you with
enough information to get started. If this applies to you, please add to the
documentation!

On a live server, you should also consider the following, to increase the
deliverability of your email, particularly if you are using the batch request feature
that might generate higher than usual volumes:

* Set up [SPF records](http://www.open-spf.org/) for your domain
* [DKIM sign](http://dkim.org/) messages
* Set up [DMARC](https://dmarc.org/)
* Consider the source IP and ensure that it isn't being used for lots of other things that might cloud your reputation - eg relaying through a service can cause problems
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
documentation](https://www.postgresql.org/docs/current/backup.html) for
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

## Deployments

We strongly recommend you make changes to your production site with a
repeatable, automated process rather than by editing it directly. Deploy
from a specific release tag and run the post-deploy script after each
deployment &mdash; see
<a href="{{ page.baseurl }}/docs/running/upgrading/">upgrading</a>
for details.
