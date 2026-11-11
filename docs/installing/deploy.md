---
layout: page
title: Deploying
---

# Deploying Alaveteli

<p class="lead">
  Alaveteli used to ship with a deployment mechanism based on Capistrano.
  This mechanism is deprecated and is being removed from Alaveteli.
</p>

<div class="attention-box danger">
  <p>
    The Capistrano deployment mechanism has not been actively maintained for
    some years and has been removed from Alaveteli's <code>develop</code>
    branch. It still ships in the 0.46.7.0 release, but it will not be
    included in future releases. Do not set up new deployments with it. The
    detailed Capistrano instructions that used to live on this page have been
    removed.
  </p>
</div>

We still recommend adopting a repeatable, automated way of deploying changes
to your
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">production server</a>
— it means there's no risk of forgetting to update a file by hand, and your
site is down for the shortest possible time when you put changes live.

To set up a server, follow the
[manual installation instructions]({{ page.baseurl }}/docs/installing/manual_install/)
(or use the [installation script]({{ page.baseurl }}/docs/installing/script/)).
To automate subsequent deployments, use standard deployment tooling of your
choice (for example configuration management or your own scripts around
`git pull` and `script/rails-post-deploy`), and remember to run
`script/rails-post-deploy` after each software update.

If you have questions about deploying Alaveteli, ask on the
[alaveteli-dev Google group](https://groups.google.com/forum/#!forum/alaveteli-dev).
