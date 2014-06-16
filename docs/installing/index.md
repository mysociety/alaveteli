---
layout: page
title: Installing
---

# Installing Alaveteli

<p class="lead">
  Although you can install Alaveteli and just change it when you need it, we
  recommend you adopt a way of <strong>deploying</strong> it automatically.
  This has several advantages, especially for your
  <a href="{{ site.baseurl }}docs/glossary/#production">production server</a>.
</p>

## Before you start

This is important: you need to decide if you are installing Alaveteli for
[development]({{ site.baseurl }}docs/glossary/#development) or
[production]({{ site.baseurl }}docs/glossary/#production).

A **development** site is one where you're going to change, customise, and
perhaps experiment while you get it up and running. You should always do this
first. In this environment you can see debug messages, and you don't need to
worry too much about the efficiency and performance of the site (because it's
not really getting lots of traffic).

A **production** site is different: you want your production site to run as
efficiently as possible, so things like caching are swiched on, and debug
messages switched off. It's important to be able to deploy changes to a
production site quickly and efficiently, so we recommend you consider using a
[deployment mechanism]({{ site.baseurl }}docs/installing/deploy/) too.

Ideally, you should also have a [staging site]({{ site.baseurl }}docs/glossary/#staging),
which is used solely to test new code in an identical environment to your
production site but before it goes live.

If you're in doubt, you're probably running a development site. Get it up and
running, play with it, customise it, and -- later -- you can install it as a
production server.

## Deployment

If you're running a production server, we **strongly recommend** you
use the Capistrano [deployment mechanism]({{ site.baseurl }}docs/installing/deploy/)
that's included with Alaveteli. Set this up and you never have to edit files on
those servers, because Capistrano takes care of that for you.

## Installing the core code

* [Install on Amazon EC2]({{ site.baseurl }}docs/installing/ami) using our AMI
* [Use the installation script]({{ site.baseurl }}docs/installing/script) which does the full installation on your own server
* [Manual installation]({{ site.baseurl }}docs/installing/manual_install) -- step-by-step instructions

If you're setting up a development server on MacOS X, we've also got
[MacOS installation instructions]({{ site.baseurl }}docs/installing/macos).

## Other installation information

Alaveteli needs to be able to send and receive email, so you need to setup your
MTA (Mail Transfer Agent) appropriately.

* [Installing the MTA]({{ site.baseurl }}docs/installing/email)
