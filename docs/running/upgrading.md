---
layout: page
title: Upgrading
---
Upgrading Alaveteli
====================

<p class="lead">
  Alaveteli is under active development &mdash; don&rsquo;t let the
  version you&rsquo;re running get too far behind our latest
  <a href="{{ page.baseurl }}/docs/glossary/#release" class="glossary__link">release</a>.
  This page describes how to keep your site up to date.
</p>

## How to upgrade the code

* If you're using Capistrano for deployment,
  simply [deploy the code]({{ page.baseurl }}/docs/installing/deploy/#usage):
  set the repo and branch in `deploy.yml` to be the version you want.
  We recommend you set this to the explicit tag name (for example,
  `0.18`, and not `master`) so there's no risk of you accidentally deploying
  a new version before you're aware it's been released.
* otherwise, you can simply upgrade by running `git pull` as the alaveteli user
  to avoid permission errors for site files (e.g. `sudo -u alaveteli git pull`)

## Run the post-deploy script

Unless you're [using Capistrano for deployment]({{ page.baseurl }}/docs/installing/deploy/),
you should always run the script `scripts/rails-post-deploy` (again, as the alaveteli user)
after each deployment. This runs any database migrations for you, plus various other
things that can be automated for deployment.

<div class="attention-box info">
  You don't need to run the script if you're using Capistrano, because the
  deployment mechanism automatically runs it for you.
</div>

## Alaveteli version numbers

Alaveteli uses a &ldquo;shifted&rdquo; version of [semver](http://semver.org)
(just as [Rails version numbering](http://guides.rubyonrails.org/maintenance_policy.html)
does). This means that version numbers are of the form: `SERIES.MAJOR.MINOR.PATCH`.

At the time of writing, the current release is `0.19.0.6`:

- Series `0`
- Major `19`
- Minor `0`
- Patch `6`

We'll use the [semver](http://semver.org) specification for Alaveteli's
version numbering when it reaches `1.0.0`.

## Master branch contains the latest stable release

The developer team policy is that the `master` branch in git should always
contain the latest stable release -- so you'll be up to date if you pull from
the `master` branch. However, on your
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">production
site</a>, you should know precisely what version you're running, and deploy
Alaveteli from a [*specific* release
tag](https://github.com/mysociety/alaveteli/releases).

Upgrading may just require pulling in the latest code -- but it may also require
other changes ("further action"). For this reason, for anything other than a
*patch* (see below), always read the 
[`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md)
document **before** doing an upgrade. This way you'll be able to prepare for any
other changes that might be needed to make the new code work.

## Patches

Patch version increases (e.g. 0.1.2.3 &rarr; 0.1.2.**4**) should not require any further action on your part. They will be backwards compatible with the current minor release version.

## Minor version increases

Minor version increases (e.g. 0.1.2.4 &rarr; 0.1.**3**.0) will usually require further action. You should read the [`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md) document to see what's changed since your last deployment, paying special attention to anything in the "Upgrade notes" sections.

Any upgrade may include new translations strings, that is, new or altered messages
to the user that need translating to your locale. You should visit <a href="{{ page.baseurl }}/docs/glossary/#transifex" class="glossary__link">Transifex</a>
and try to get your translation up to 100% on each new release. Failure to do
so means that any new words added to the Alaveteli source code will appear in
your website in English by default. If your translations didn't make it to the
latest release, you will need to download the updated `app.po` for your locale
from Transifex and save it in the `locale/` folder.

Minor releases will be backwards compatible with the current major release version.

## Major releases

Major version increases (e.g. 0.1.2.4 &rarr; 0.2.0.0) will usually require further action. You should read the [`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md) document to see what's changed since your last deployment, paying special attention to anything in the "Upgrade notes" sections.

Only major releases may remove existing functionality. You will be warned about the removal of functionality with a deprecation notice in a minor release prior to the major release that removes the functionality.

## Series releases

Special instructions will accompany series releases.

## Deprecation notices

You may start to see deprecation notices in your application log. They will look like:

    DEPRECATION WARNING: Object#id will be deprecated; use Object#object_id

Deprecation notices allow us to communicate with you that some functionality will change or be removed in a later release of Alaveteli.

### What to do if you see a deprecation notice

You will usually see a deprecation notice if you have been using functionality in your theme that is now due to change or be removed. The notice should give you a fair explanation of what to do about it. Usually it will be changing or removing methods. The [changelog](https://github.com/mysociety/alaveteli/blob/develop/doc/CHANGES.md) will include more detailed information about the deprecation and how to make the necessary changes.

If you're ever unsure, don't hesitate to ask in the [developer mailing list](https://groups.google.com/group/alaveteli-dev) or [Alaveteli IRC channel](http://www.irc.mysociety.org/).

### When will the change take place?

We introduce deprecation notices in a **minor** release. The following **major** release will make the change unless otherwise stated in the deprecation notice.
