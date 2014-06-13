---
layout: page
title: Upgrading
---
## Upgrading Alaveteli

The developer team policy is that the master branch in git should always
contain the latest stable release. Therefore, in production, you should usually
have your software deployed from the master branch, and an upgrade can be
simply `git pull`.

Patch version increases (e.g. 1.2.3 &rarr; 1.2.**4**) should not require any further
action on your part.

Minor version increases (e.g. 1.2.4 &rarr; 1.**3**.0) will usually require further
action. You should read the [`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md) document to see what's changed since
your last deployment, paying special attention to anything in the "Upgrade notes"
sections.

Any upgrade may include new translations strings, i.e. new or altered messages
to the user that need translating to your locale. You should visit Transifex
and try to get your translation up to 100% on each new release. Failure to do
so means that any new words added to the Alaveteli source code will appear in
your website in English by default. If your translations didn't make it to the
latest release, you will need to download the updated `app.po` for your locale
from Transifex and save it in the `locale/` folder.

Unless you're using Capistrano for deployment, you should always run the script `scripts/rails-post-deploy` after each
deployment. This runs any database migrations for you, plus various other
things that can be automated for deployment.

