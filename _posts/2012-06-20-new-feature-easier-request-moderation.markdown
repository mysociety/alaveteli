---
author: Seb
comments: true
date: 2012-06-20 13:11:12+00:00
layout: post
slug: new-feature-easier-request-moderation
title: 'New feature: easier request moderation'
wordpress_id: 361
categories:
- Uncategorised
---

WhatDoTheyKnow [has been criticised in the past](http://2040infolawblog.com/2012/02/09/do-they-know-what/) for not doing more to discourage frivolous or abusive requests.  The vast majority of requests for information are sensible, but we get a some citizens using the site to vent their anger or frustration at something, and a reasonable number of requests which are not really FOI requests at all, made by people who misunderstand the purpose of the site.

Alaveteli has always supported hiding requests that are unsuitable, but in [version 0.6](/development/2012/06/20/alaveteli-0-6-fancy-admin-released/) we've added some new functionality that makes the process smoother and faster.

First, we allow any logged in user to report a request for moderation by an administrator.  This is important because there's no way we could support the moderation of requests before they are published on the site:

{% include image.html url="/assets/img/report.png" description="Reporting a request" width="651" %}

Requests that have been reported now appear in a worklist on the home page of Alaveteli's administrative interface:

{% include image.html url="/assets/img/review.png" description="Reported requests" width="504" %}

When a moderator clicks through to the edit page for the request, they are now presented with radio buttons to select a reason why the request should be hidden (if any).  A text box appears prefilled with suggested text, and when the moderator hits the "hide request" button, this message is emailed to the requestor notifying them that their message has been hidden:

{% include image.html url="/assets/img/hide.png" description="Interface for hiding a request" width="635" %}


Let us know if you find this useful, and if you think it needs any more tweaking!
