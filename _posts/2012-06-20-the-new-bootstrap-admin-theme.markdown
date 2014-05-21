---
author: sebbacon
comments: true
date: 2012-06-20 12:27:18+00:00
layout: post
slug: the-new-bootstrap-admin-theme
title: 'New feature: the new bootstrap admin theme'
wordpress_id: 357
categories:
- Development
---

One of the major new features in the latest release of Alaveteli is a more attractive (and hopefully more usable) admin theme.  Here's a before-and-after shot of the home page:

[![](http://blogs.mysociety.org/alaveteliorg/files/2012/06/oldnew.png)](http://blogs.mysociety.org/alaveteliorg/files/2012/06/oldnew.png)

The theme was started at AlaveteliCon by [@wombleton](https://twitter.com/#!/wombleton).  It's based on Twitter's [Bootstrap framework](http://twitter.github.com/bootstrap/), a CSS-and-javascript foundation for layout and styling of websites.  It tries to collapse the large amounts of data often found on a single page into smaller chunks that can be scanned more easily.

When I started integrating the new code into the Alaveteli core, I realised that this might be quite a big and potentially unwanted step for users who are used to the old interface.  So I moved all the interface changes [into their own theme](https://github.com/sebbacon/adminbootstraptheme), which can be installed or uninstalled by changing [a line in the configuration file](https://github.com/sebbacon/alaveteli/blob/2e69a53ff5c3e15dd5a7a0fcb5f8fcedf3d6f778/config/general.yml-example#L37).

The upshot of this is that instead of specifying a single theme in your site's configuration file, you can now specify a list of themes.  When Alaveteli needs to display a help page, or a template, or a CSS file, it starts by looking in the first theme on the list.  If the resource isn't there, it works through the other themes in order, until it falls back to the resources provided in Alaveteli itself.  This may be useful if you want to borrow someone else's theme but just change the logo or colours; or perhaps if you want to temporarily add a banner at the top of your site to make an announcement about a change in FOI laws in your jurisdiction.

In new installations of Alaveteli 0.6, the admin theme is installed by default, but existing installations that want to try the theme out will need to add it to their config file,[ as per the sample config](https://github.com/sebbacon/alaveteli/blob/2e69a53ff5c3e15dd5a7a0fcb5f8fcedf3d6f778/config/general.yml-example#L37) supplied with Alaveteli.

The new admin theme includes some new functionality that isn't available in the old theme, and the old theme should be considered deprecated.  You can expect the new admin theme to be merged into the Alaveteli core (and the old theme to disappear) by version 0.7, so if you don't like the new look, shout out on the [mailing list](http://groups.google.com/group/alaveteli-dev) before it's too late!
