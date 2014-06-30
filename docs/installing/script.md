---
layout: page
title: Installation script
---

# Installation  script

<p class="lead">
  If you prefer to use your own server, we've provided an installation script which does most of the work for you.
</p>

Note that there are [other ways to install Alaveteli]({{ site.baseurl }}docs/installing/).

## Installing with the installation script

If you have a clean installation of Debian squeeze 64-bit or Ubuntu precise, you can
use an install script in our commonlib repository to set up a working instance
of Alaveteli. This is not suitable for production (it runs in development mode,
for example) but should set up a functional installation of the site.

**Warning: only use this script on a newly installed server – it will make
significant changes to your server’s setup, including modifying your nginx
setup, creating a user account, creating a database, installing new packages
etc.**

To download the script, run the following command:

    curl -O https://raw.githubusercontent.com/mysociety/commonlib/master/bin/install-site.sh

If you run this script with `sh install-site.sh`, you'll see its usage message:

    Usage: ./install-site.sh [--default] <SITE-NAME> <UNIX-USER> [HOST]
    HOST is only optional if you are running this on an EC2 instance.
    --default means to install as the default site for this server,
    rather than a virtualhost for HOST.

In this case `<SITE-NAME>` should be `alaveteli`. `<UNIX-USER>` is the name of
the Unix user that you want to own and run the code. (This user will be created
by the script.)

The `HOST` parameter is a hostname for the server that will be usable
externally – a virtualhost for this name will be created by the script, unless
you specified the `--default` option. This parameter is optional if you are on
an EC2 instance, in which case the hostname of that instance will be used.

For example, if you wish to use a new user called `alaveteli` and the hostname
`alaveteli.127.0.0.1.xip.io`, creating a virtualhost just for that hostname,
you could download and run the script with:

    sudo sh install-site.sh alaveteli alaveteli alaveteli.127.0.0.1.xip.io

([xip.io](http://xip.io/) is a helpful domain for development.)

Or, if you want to set this up as the default site on an EC2 instance, you
could download the script, make it executable and then invoke it with:

    sudo ./install-site.sh --default alaveteli alaveteli

When the script has finished, you should have a working copy of the website,
accessible via the hostname you supplied to the script.

If you have any problems or questions, please ask on the [Alaveteli Google
Group](https://groups.google.com/forum/#!forum/alaveteli-dev) or [report an
issue](https://github.com/mysociety/alaveteli/issues?state=open).

