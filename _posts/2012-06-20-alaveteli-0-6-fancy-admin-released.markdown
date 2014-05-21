---
author: sebbacon
comments: true
date: 2012-06-20 11:06:09+00:00
layout: post
slug: alaveteli-0-6-fancy-admin-released
title: Alaveteli 0.6 "fancy admin" released!
wordpress_id: 354
categories:
- Development
---

Finally Alaveteli 0.6 is out of the door!  Grab it from the [github master branch](https://github.com/sebbacon/alaveteli/) and try it out.  The most obvious new feature is a glossy new administrative interface, based on work started at AlaveteliCon by [@wombleton](https://twitter.com/#%21/wombleton).  If you are upgrading, be sure to read the upgrade notes in [CHANGES.md](https://github.com/sebbacon/alaveteli/blob/master/doc/CHANGES.md), and the [new section in the install docs](https://github.com/sebbacon/alaveteli/blob/master/doc/INSTALL.md#upgrading-alaveteli) about upgrading Alavetel[i](https://github.com/sebbacon/alaveteli/blob/master/doc/INSTALL.md#upgrading-alaveteli).  Drop a note to the [alaveteli-dev mailing list](http://groups.google.com/group/alaveteli-dev) if you need any help with your upgrade.

[A full list of changes](https://github.com/sebbacon/alaveteli/issues?milestone=13&state=closed) is on Github.  Interesting features and bugfixes include:



	
  * Most Ruby dependencies are now handled by Bundler (thanks [@mckinneyjames](https://twitter.com/#!/mckinneyjames)!)

	
  * Support for invalidating accelerator cache -- this makes it much  less likely, when using Varnish, that users will be presented with stale  content.  Fixes [issue #436](https://github.com/sebbacon/alaveteli/issues/436)

	
  * Adding a `GA_CODE` to `general.yml` will cause the relevant Google Analytics code to be added to your rendered pages

	
  * It is now possible to have more than one theme installed.  The  behaviour of multiple themes is now layered in the reverse order they're  listed in the config file.  See the variable `THEME_URLS` in `general.yml-example` for an example.

	
  * A new, experimental theme for the administrative interface.  It's  currently packaged as a standalone theme, but will be merged into the  core once it's been tested and iterated in production a few times.   Thanks to [@wombleton](https://twitter.com/#!/wombleton) for kicking this off!

	
  * Alert subscriptions are now referred to as "following" a request (or  group of requests) throughout the UI.  When a user "follows" a request,  updates regarding that request are posted on a new "wall" page.  Now  they have a wall, users can opt not to receive alerts by email.

	
  * New features to [support fast post-moderation of bad requests](http://www.alaveteli.org/2012/06/new-feature-easier-request-moderation/): a  button for users to report potentially unsuitable requests, and a form  control in the administrative interface that hides a request and sends  the user an email explaining why.

	
  * A bug which prevented locales containing underscores (e.g. `en_GB`) was fixed ([issue #503](https://github.com/sebbacon/alaveteli/issues/503))

	
  * Error pages are now presented with styling from themes


There are some blog posts about some of the new features here:

	
  * [The new admin theme](http://www.alaveteli.org/2012/06/the-new-bootstrap-admin-theme/)

	
  * [The request moderation features](http://www.alaveteli.org/2012/06/new-feature-easier-request-moderation/)

	
  * ["Following" and the "wall"](http://www.alaveteli.org/2012/06/new-feature-following-and-the-wall/)

	
  * [Bundler](http://www.alaveteli.org/2012/06/new-for-developers-bundler-support/)


