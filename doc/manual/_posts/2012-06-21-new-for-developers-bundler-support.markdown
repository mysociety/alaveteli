---
author: Seb
comments: true
date: 2012-06-21 06:52:08+00:00
layout: post
slug: new-for-developers-bundler-support
title: 'New for developers: bundler support'
wordpress_id: 373
categories:
- Blog
---

Thanks to lots of hard work from [@mckinneyjames](https://twitter.com/#!/mckinneyjames), Alaveteli now uses [Bundler](http://gembundler.com/) wherever possible to satisfy its dependencies.

We have a few such dependencies, like `recaptcha` and `rmagick`.  Previously we installed these from system packages on Debian.  The advantages of using Bundler are:




  * We can upgrade to newer versions more quickly than Debian packages allow


  * It's the standard way of packaging software in Rails 3, to which we will migrate in due course (in fact, we will probably skip straight to Rails 4...)


  * It brings the process of getting a working setup in OS X closer to that of building the same thing on a Linux-based system



It's not utopia -- the first run of "bundle install" on a new system will take a very long time, because Xapian has to be compiled from scratch; and we can't remove our non-rubygems dependencies like gnuplot and memcached.  However, as part of the slow process of moving to a modern Rails setup, this is a major step forward.


