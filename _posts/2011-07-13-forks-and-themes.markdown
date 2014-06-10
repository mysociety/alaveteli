---
author: Seb
comments: true
date: 2011-07-13 09:46:52+00:00
layout: post
slug: forks-and-themes
title: Forks and themes
wordpress_id: 16
categories:
- Blog
- Development
- Partners
---

Over the past few days, I've completed merging the Kosovan fork of the code back into the main Alaveteli software ([here's an email about it](https://groups.google.com/group/alaveteli-dev/browse_thread/thread/624ca44d2a8121d4) on the dev mailing list).

In non-technical terms: the team from Kosovo have been working to a tight deadline without any help from me (because I was working on other things while we waited for funding to come through).  The quickest way for them to change Alaveteli to meet their needs (e.g. changing the design, making the templates work in different languages, etc) was to alter the core Alaveteli code.

This meant they could move swiftly towards deployment; however, the down side was that they were no longer running off the same code base as WhatDoTheyKnow.  As a result, they were missing out on bug fixes and improvements that mySociety were making to the code, and mySociety were missing out on things like the internationalised templates.

{% include image.html url="/assets/img/sq.png" description="The current Informata Zyrtare theme" width="500" %}

_Merging_ is the process of taking someone else's changes and mixing them with your own changes to create a new, combined version of the software.

This is now complete, which means we can once again start to benefit from each others' work.

As a side effect, I needed to come up with ways to keep customisations separate from the core code.  All such customisations should now live in "themes", which I have [started to document](/customising/themes).  One such theme is the Informata Zyrtare theme, which is now on Github, should anyone want to experiment with it.
