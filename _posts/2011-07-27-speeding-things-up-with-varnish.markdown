---
author: sebbacon
comments: true
date: 2011-07-27 15:10:01+00:00
layout: post
slug: speeding-things-up-with-varnish
title: Speeding things up with Varnish
wordpress_id: 49
categories:
- Uncategorised
---

On [WhatDoTheyKnow](http://www.whatdotheyknow.com), the Alaveteli software has lately been grinding to a halt.   It's hard to pinpoint the exact cause, but it's related to many of the following points:



	
  * Rails and ruby (especially ruby 1.8, which we're currently running) being relatively slow in general

	
  * The size of our database (two tables in particular were taking up more than 40GB space).  In particular this meant our backups were hogging I/O.

	
  * Our heavy use of Xapian, on the same machine as the large database: lots of disk seeks, particularly during costly batch walk-and-retrieve operations (e.g. sending out email alerts)

	
  * Some areas where the database could be better optimised

	
  * The fact that Varnish wasn't actually caching many of our pages, as they didn't have any relevant cache headers set up (in fact, the Rails default is for them to have `Cache-control: private` headers.


Really, I should have done some baseline performance tests, incrementally introduced improvements, and re-profiled the site with each improvement.  However, I've got loads of other things to do, and there are data protection issues with grabbing a copy of the entire current WhatDoTheyKnow database, so in consultation with some other team members, I just picked some of the lowest-hanging fruit.

The detail of the discussion and outcomes are [recorded in the issue tracker](https://github.com/sebbacon/alaveteli/issues/86), but it turns out that the biggest, most immediate effect was to simply reduce the number of requests that made it to the Rails application in the first place -- as is so often the case in applications like this.

The moral: on all but the smallest Alaveteli website, deploy it behind a caching proxy like [Varnish](https://www.varnish-cache.org/).  I'll write up some notes in the documentation in due course [edit: [a sample varnish configuration](https://github.com/sebbacon/alaveteli/blob/master/config/varnish-alaveteli.vcl) is now supplied with the software).

You can see the difference on the resource usage of the server running WhatDoTheyKnow on this chart -- I deployed the caching-related changes around 08:15 on these charts:

[![](http://blogs.mysociety.org/alaveteliorg/files/2011/07/performance.png)](http://blogs.mysociety.org/alaveteliorg/files/2011/07/performance.png)
