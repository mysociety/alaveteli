---
layout: page
title: Installation from AMI
---

# Installation on Amazon EC2

<p class="lead">
  We've made an Amazon Machine Image (AMI) so you can quickly deploy on Amazon
  EC2. This is handy if you just want to evaluate Alaveteli, for example.
</p>

Note that there are [other ways to install Alaveteli]({{ page.baseurl }}/docs/installing/).

## Installing from our AMI

To help you try out Alaveteli, we have created an AMI with a basic installation
of Alaveteli, which you can use to create a running server on an Amazon EC2
instance. This creates an instance that runs as a
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">development site</a>.
If you want to use this for a 
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">production site</a>,
you must
[change the configuration]({{ page.baseurl }}/docs/customising/config/#staging_site).

<div class="attention-box">
  <p>
    <strong>What's in the AMI?</strong>
    The AMI gives you exactly the same thing as the 
    <a href="{{ page.baseurl }}/docs/installing/script/">installation script</a>
    does. You get an Alaveteli website powered by Rails running the Thin
    application server under nginx, using a postgreSQL database. All this
    running on Amazon's EC2 servers, ready to be
    <a href="{{ page.baseurl }}/docs/customising/">configured and customised</a>.
  </p>
</div>

Amazon instances are graded by size. Unfortunately, the *Micro* instance does
not have enough memory for Alaveteli to run -- and that's the only size
available on Amazon's free usage tier. You need to use a *Small* instance or
larger, which Amazon will charge you for.

### Using Amazon web services

To do this, you'll need:

   * an account with Amazon
   * a SSL key pair (the Amazon web service screens guide you through this)

If you don't have these already, you'll need to create them. See Amazon's
introduction on
[running a Virtual Server on AWS](http://docs.aws.amazon.com/gettingstarted/latest/awsgsg-intro/gsg-aws-virtual-server.html).

### Launch the instance

Once you're logged in to Amazon's service, and navigated to the **EC2
Management Console**, you can launch the instance. If you prefer to do this
manually, you can find the AMI in the "EU West (Ireland)" region, with the ID
`ami-d2c812a1` and name “Basic Alaveteli installation 2015-09-17”.
Alternatively, use this link:

<p class="action-buttons">
  <a href="https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-d2c812a1" class="button">launch
  instance with Alaveteli installation AMI</a>
</p>

When the instance launches, the first thing you need to choose is the instance
*type*. Remember that the *Micro* type does not have enough memory to run
Alaveteli, so you must choose at least *Small* or *Medium* -- note that these
are not available on Amazon's free usage tier.

When the instance is created, the Amazon interface presents you with a lot of
choices about its configuration. You can generally accept the defaults for
everything, except the Security Groups. It's safe to click on **Review and
Launch** right away (rather than manually configuring all the instance details)
because you still get an opportunity to configure the security groups. Click on
**Edit Security Groups** on the summary page before you hit the big **Launch**
button.

You must choose Security Groups that allow at least inbound HTTP, HTTPS, SSH
and, if you want to test incoming mail as well, SMTP. Amazon's settings here
let you specify the IP address(es) from which your instance will accept
requests. It's good practice to restrict these (if in doubt, choose a *Source*
of "My IP" for them all -- except incoming HTTP: for that, simpy to set
*Source* to "Anywhere"). You can change any of these settings later if you need
to.

### Log into the server (shell)

You need access to the server's command line shell to control and configure
your Alaveteli site.

To access the server, use `ssh` and the `.pem` file from your SSL key pair.
Change the `.pem` file and instance ID to match your own in this command, which
connects to your server and logs you in as the user called `ubuntu`. Issue this
command from your own machine, to log in to the server:

    ssh -i path-to/your-key-pair.pem ubuntu@instance-id.eu-west-1.compute.amazonaws.com

You won't be asked for a password, because the `.pem` file you supply with the
`-i` option contains the authorisation that matches the one at the other end,
on the server. You will be logged into the shell on your new Alaveteli server,
and can issue Unix commands to it.

### Smoke test: start Alavateli

You must configure your Alavateli site, but if you just want to see that you've
got your instance running OK, you *can* fire it up right away. Ideally, you
should skip this step and go straight to the configuration... but we know most
people like to see something in their browser first. ;-)

On the command line shell, as the `ubuntu` user, start Alaveteli by doing:

    sudo service alaveteli start

Find the "public DNS" URL of your EC2 instance from the AWS console, and look
at it in a browser. It will be of the form
`http://your-ec2-hostname.eu-west-1.compute.amazonaws.com`. You'll see your
Alaveteli site there.

Your site isn't configured yet, so *this is insecure* (for example, you haven't
set your own passwords for access to the administration yet), so once you've
seen this running, bring the Alaveteli site down with:

    sudo service alaveteli stop


### Shell users: `ubuntu` and `alaveteli`

When you log into your instance's command line shell, you must do so as the
`ubuntu` user. This user can `sudo` freely to run commands as root. However,
the code is actually owned by (and runs as) the `alaveteli` user.

You will need to 
[customise the site's configuration]({{ page.baseurl }}/docs/customising/config/).
Do this by logging into your EC2 server and editing the `general.yml`
configuration file.

The configuration file you need to edit is
`/var/www/alaveteli/alaveteli/config/general.yml`. For example, use the `nano`
editor (as the `alaveteli` user) like this:

    ubuntu@ip-10-58-191-98:~$ sudo su - alaveteli
    alaveteli@ip-10-58-191-98:~$ cd alaveteli
    alaveteli@ip-10-58-191-98:~/alaveteli$ nano config/general.yml

After making changes to that file, you'll need to start the application
server (use `restart` rather than `start` if it's already running):

    alaveteli@ip-10-58-191-98:~/alaveteli$ logout
    ubuntu@ip-10-58-191-98:~$ sudo service alaveteli start

Your site will be running at the public URL again, which is of the form
`http://your-ec2-hostname.eu-west-1.compute.amazonaws.com`.

If you have any problems or questions, please ask on the [Alaveteli developer mailing list](https://groups.google.com/forum/#!forum/alaveteli-dev) or [report an issue](https://github.com/mysociety/alaveteli/issues?state=open).


##What next?

Check out the [next steps]({{ page.baseurl }}/docs/installing/next_steps/).
