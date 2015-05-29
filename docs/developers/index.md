---
layout: page
title: For developers
---

# Information for developers

<p class="lead">
    Alaveteli is an open source project. Full-time mySociety developers together with devs from all around the world actively contribute to the codebase. These notes and links will help you if you want to help too.
</p>

* The software is written in **Ruby on Rails 3.x**. We support postgresql as
  the backend database. A configured mail transfer agent (MTA) like exim,
  postfix or sendmail is necessary to parse incoming emails. We have production
  sites deployed on Debian (Squeeze and Wheezy) and Ubuntu (12.04 LTS). For performance
  reasons, we recommend the use of [Varnish](https://www.varnish-cache.org).

* To help you understand what the code is doing, read this [high-level
  overview]({{ page.baseurl }}/docs/developers/overview/), which includes a diagram of
  the models and how they are related.

* See the [API documentation]({{ page.baseurl }}/docs/developers/api/) for how to get
  data into or out of Alaveteli.

* If you need to change or add strings in the interface, see our [guidelines
  for internationalisation](http://mysociety.github.io/internationalization.html
  ), which include notes about our use of `gettext`.

* We use the [git flow branching
  model](http://nvie.com/posts/a-successful-git-branching-model/),
  the latest development version is always found on the
  [develop branch](https://github.com/mysociety/alaveteli). The
  latest stable version is always on the [master
  branch](https://github.com/mysociety/alaveteli/tree/master). If you plan to collaborate
  on the software, you may find the [git flow
  extensions](https://github.com/nvie/gitflow) useful.

* Installing the software is a little involved, though it's getting easier. If
  you stick to Debian or Ubuntu, it should be possible to get a running version
  within a few hours. If you've got your own server, run the
  [installation script]({{ page.baseurl }}/docs/installing/script/), or follow the
  instructions for a
  [manual installation]({{ page.baseurl }}/docs/installing/manual_install/).
  Alternatively, there's an [Alaveteli EC2 AMI]({{ page.baseurl }}/docs/installing/ami/)
  that might help you get up and running quickly.
  [Get in touch]({{ page.baseurl }}/community/) on the project mailing list or IRC
  for help.

* A standard initial step for customising your deployment is [writing a
  theme]({{ page.baseurl }}/docs/customising/themes/). **If you only read one thing,
  it should be this!**

* Like many Ruby on Rails sites, the software is not hugely performant (see
  [these notes about performance issues](https://github.com/mysociety/alaveteli/wiki/Performance-issues) gathered over time with
  WhatDoTheyKnow). The site will run on a server with 512MB RAM but at least
  2GB is recommended. Deployment behind [Varnish](https://www.varnish-cache.org) is also fairly essential. See
  [production server best practices]({{ page.baseurl }}/docs/running/server/) for more.

* There's a number of [proposals for enhancements](https://github.com/mysociety/alaveteli/wiki/Proposals-for-enhancements),
  such as more user-focused features, but see also...

* ...the [github issues](https://github.com/mysociety/alaveteli/issues). We
  mark issues with the label **suitable for volunteers** if we think they are
  especially suitable for diving into if you're just looking for something
  relatively small to get your teeth into.

* We try to ensure every commit has a corresponding issue in the issue tracker.
  This makes changelogs easier as we can gather all the fixes for a particular
  release against a milestone in the issue tracker, [like this 0.4
  release](https://github.com/mysociety/alaveteli/issues?milestone=7&state=close
  d).

* If you're experiencing memory issues, [this blog post about some strategies
  used in the
  past](https://www.mysociety.org/2009/09/17/whatdotheyknow-growing-pains-and-ruby-memory-leaks/) might be useful.

* If you're coding on a mac, see these [MacOS X installation notes]({{ page.baseurl }}/docs/installing/macos/). <!-- [[OS X Quickstart]] -->

* We try to adhere to similar good practice across all our projects: see
  [mysociety.github.io](http://mysociety.github.io/) for things like our
  [coding standards](http://mysociety.github.io/coding-standards.html)
