---
layout: page
title: Installing on MacOS X
---

# Installation on MacOS X

<p class="lead">
  Native installation on macOS is no longer maintained. If you want to get
  Alaveteli running on your Mac for development, we recommend using Docker.
</p>

Note that there are [other ways to install Alaveteli]({{ page.baseurl }}/docs/installing/).

## Use Docker for development on macOS

The older native macOS installation instructions (covering Homebrew, RVM and
old versions of Ruby and PostgreSQL) are out of date and no longer supported.

Instead, the recommended way to get a development site running on a Mac is to
[install into a Docker development container]({{ page.baseurl }}/docs/installing/docker/).
Docker takes care of the dependencies for you and gives you a consistent
environment that matches the one we test against, so you don't need to install
and configure everything by hand on macOS.

## Advanced or production installations

Docker is intended for local development and is not suitable for production.
When you're ready to run a production site, install on a Linux server by
following the [manual installation instructions]({{ page.baseurl }}/docs/installing/manual_install/).
