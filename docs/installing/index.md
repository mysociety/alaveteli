---
layout: page
title: Installing
---

# Installing Alaveteli

<p class="lead">
  There are a number of ways to install Alaveteli, but we recommend
  you begin with the Vagrant installation to get a development
  site up and running.
</p>

## Before you start

This is important: there is a difference between installing Alaveteli for
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">development</a> or
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">production</a>.

You *always* start with a **development** site. This is one you're going to change, customise, and
perhaps experiment while you get it up and running. Every Alaveteli installation requires some customisation (it's designed this way!)
including creating your own 
<a href="{{ page.baseurl }}/docs/glossary/#theme" class="glossary__link">theme</a>. In this environment you can see debug messages, and you don't need to
worry too much about the efficiency and performance of the site (because it's
not really getting lots of traffic).

A **production** site is different: you want your production site to run as
efficiently as possible, so things like caching are switched on, and debug
messages switched off. It's also important to be able to deploy changes to a
production site quickly and efficiently, so we recommend you use a
[deployment mechanism]({{ page.baseurl }}/docs/installing/deploy/) too.

## The installation path

The path to getting Alaveteli up and running almost never starts
on the remote server where you want the website to run. You _must_
[customise Alaveteli]({{ page.baseurl }}/docs/customising/) before it's ready for the public to use, so get
it running in a development environment first — and that nearly always
means on your local machine.

So the best way to get started is to 
[install locally using Vagrant]({{ page.baseurl }}/docs/installing/vagrant/)
— that's easiest because it takes care of local dependencies for you.
In order to customise your installation, you'll need to make your own
<a href="{{ page.baseurl }}/docs/glossary/#theme"  class="glossary__link">theme</a>
and, eventually, that theme will go into its own
<a href="{{ page.baseurl}}/docs/glossary/#git" class="glossary__link">git
repo</a>. Only when you've got this far can you move onto a
<a href="{{ page.baseurl}}/docs/glossary/#staging" class="glossary__link">staging site</a>.
Here you can test the code in an identical environment to your production site.
The very last step is to go live.

<img src="{{page.baseurl}}/assets/img/alaveteli-install-path.svg" />

Depending on the resources you have available, it might be that your staging server becomes your production server.

## How to install the Alaveteli code

* [Install into a Vagrant virtual development environment]({{ page.baseurl }}/docs/installing/vagrant/)
  -- the easiest way to get a development version up and running

<div class="attention-box info">
    Although we recommend Vagrant for development, there are of course other ways
    to install Alaveteli. Vagrant is never suitable for production (but remember
    that you won't need a production site until you've done a development
    deployment). We've made an Amazon Machine Image (AMI) so you can quickly
    deploy on Amazon EC2. If you prefer to use your own server, there's an
    installation script which does most of the work for you, or you can follow
    the manual installation instructions.
</div>
<div class="attention-box helpful-hint">
    <strong>
      If you're not sure which one you want,
      <a href="{{ page.baseurl }}/docs/installing/vagrant/">install using
      Vagrant</a> first!
    </strong>
</div>

* [Install on Amazon EC2]({{ page.baseurl }}/docs/installing/ami/) using our AMI
* [Use the installation script]({{ page.baseurl }}/docs/installing/script/) which does the full installation on your own server
* [Manual installation]({{ page.baseurl }}/docs/installing/manual_install/) -- step-by-step instructions

<!--
If you're setting up a development server on MacOS X, we've also got
[MacOS installation instructions]({{ page.baseurl }}/docs/installing/macos/).
-->

## Other installation information

Alaveteli needs to be able to send and receive email. If you're installing
manually, you need to
[set up your MTA (Mail Transfer Agent) appropriately]({{page.baseurl }}/docs/installing/email/).
The other install methods will do this for you.

* [Installing the MTA]({{ page.baseurl }}/docs/installing/email/)

## Deployment

When you set up your production server, we **strongly recommend** you
use the Capistrano [deployment mechanism]({{ page.baseurl }}/docs/installing/deploy/)
that's included with Alaveteli. Set this up and you never have to edit files on
those servers, because Capistrano takes care of that for you.
