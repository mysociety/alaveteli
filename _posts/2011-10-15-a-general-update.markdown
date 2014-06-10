---
author: Seb
comments: true
date: 2011-10-15 09:36:42+00:00
layout: post
slug: a-general-update
title: A general update
wordpress_id: 78
categories:
- Blog
---

As I'm about to go on paternity leave, I thought it would be a good time to summarise what's been happening the last few months.

The Alaveteli software is starting to look in reasonable shape.  We have a lovely new theme designed by Nick Mason of [thetuttroom.com](http://www.thetuttroom.com), which can be seen on the new demo server set up at [http://demo.alaveteli.org](http://demo.alaveteli.org).  It no longer takes a day or more to install the software; we have some way to go to achieve a 5-minute install, but the[ documentation is better](/installing), and it's [now possible to run a development version on Mac OS X](/installing/macos).

There have been lots of small improvements to the user interface, such as the beginnings of a [user-friendly advanced search](http://demo.alaveteli.org/en/search), and a better way for the user to decide who followup messages should go to.  In the backend, moderators' lives are getting a bit easier now that user alert bounces are handled automatically.  There's also now some spam protection in the form of reCaptchas (only for users coming from abroad).  Finally, the software performs around 30% faster on [WhatDoTheyKnow](http://www.whatdotheyknow.com), thanks to new caching settings and a better backend storage system for emails.

On the development front, we have adopted the [git flow model](http://nvie.com/posts/a-successful-git-branching-model/) for managing branches and releases using git, which seems to be going quite well.  We are trying to ensure all commits have associated issues in the issue tracker, which means we can use it as a fairly reliable change log for the software.

Beyond the software itself, the most exciting news is that there are now two more Alaveteli websites launched: [AskTheEU](http://www.asktheeu.org) and [InformataZyrtare](http://informatazyrtare.org) (Kosovo).  The sites look great, and the first requests are starting to come in.

Over the next few months, we hope to continue to support groups in other countries who are hoping to launch Alaveteli websites.  We also hope to learn from the recent new launches to make it easier to customise and deploy Alaveteli.  If you're thinking about using Alaveteli, please have a read of our new [Getting Started guide](/getting_started), and get in touch!


