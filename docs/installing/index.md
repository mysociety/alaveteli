---
layout: page
title: Installing
---

# Installing Alaveteli

<p class="lead">
  There are a number of ways to install Alaveteli.
  We've made an Amazon Machine Image (AMI) so you can quickly deploy on
  Amazon EC2 (handy if you just want to evaluate it, for example).
  If you prefer to use your own server, there's an installation script
  which does most of the work for you, or you can follow the manual
  installation instructions.
</p>

## Before you start

This is important: you need to decide if you are installing Alaveteli for
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">development</a> or
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">production</a>.

A **development** site is one where you're going to change, customise, and
perhaps experiment while you get it up and running. You should always do this
first. In this environment you can see debug messages, and you don't need to
worry too much about the efficiency and performance of the site (because it's
not really getting lots of traffic).

A **production** site is different: you want your production site to run as
efficiently as possible, so things like caching are swiched on, and debug
messages switched off. It's important to be able to deploy changes to a
production site quickly and efficiently, so we recommend you consider using a
[deployment mechanism]({{ page.baseurl }}/docs/installing/deploy/) too.

Ideally, you should also have a
<a href="{{ page.baseurl }}/docs/glossary/#staging" class="glossary__link">staging site</a>,
which is used solely to test new code in an identical environment to your
production site before it goes live.

If you're in doubt, you're probably running a development site. Get it up and
running, play with it, customise it, and -- later -- you can install it as a
production server.

## Deployment

If you're running a production server, we **strongly recommend** you
use the Capistrano [deployment mechanism]({{ page.baseurl }}/docs/installing/deploy/)
that's included with Alaveteli. Set this up and you never have to edit files on
those servers, because Capistrano takes care of that for you.

## Installing the core code

* [Install into a Vagrant virtual development environment]({{ page.baseurl }}/docs/installing/vagrant/) -- a good choice for development, and playing around with the site.
* [Install on Amazon EC2]({{ page.baseurl }}/docs/installing/ami/) using our AMI
* [Use the installation script]({{ page.baseurl }}/docs/installing/script/) which does the full installation on your own server
* [Manual installation]({{ page.baseurl }}/docs/installing/manual_install/) -- step-by-step instructions

If you're setting up a development server on MacOS X, we've also got
[MacOS installation instructions]({{ page.baseurl }}/docs/installing/macos/).

## Other installation information

Alaveteli needs to be able to send and receive email. If you're installing manually, you need to [setup your
MTA (Mail Transfer Agent) appropriately]({{ page.baseurl }}/docs/installing/email/). The other install methods will do this for you.

* [Installing the MTA]({{ page.baseurl }}/docs/installing/email/)
