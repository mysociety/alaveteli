---
layout: page
title: Installing
---

# Installing Alaveteli

<p class="lead">

	There are a number of ways to install Alaveteli.
	We've made an Amazon Machine Image (AMI) so you can quickly deploy on Amazon EC2 (handy if you just want to evaluate it, for example). If you prefer to use your own server, there's an installation script which does most of the work for you.
</p>

## Installing the core code

* [Install on Amazon EC2]({{ site.baseurl }}installing/ami) using our AMI
* [Use the installation script]({{ site.baseurl }}installing/script) which does the full installation on your own server
* [Manual installation]({{ site.baseurl }}installing/script) -- step-by-step instructions

If you're setting up a development server on MacOS X, we've also got [MacOS installation instructions]({{ site.baseurl }}installing/macos).

## Other installation information

Alaveteli needs to be able to send and receive email, so you need to setup your MTA (Mail Transfer Agent) appropriately.

* [Installing the MTA]({{ site.baseurl }}installing/exim4)


