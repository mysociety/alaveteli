---
layout: page
title: Installation from AMI
---

# Installation on Amazon EC2

<p class="lead">
  We've made an Amazon Machine Image (AMI) so you can quickly deploy on Amazon EC2. This is handy if you just want to evaluate Alaveteli, for example.
</p>

Note that there are [other ways to install Alaveteli]({{ site.baseurl }}docs/installing/).

## Installing from our AMI

To help people try out Alaveteli, we have created an AMI (Amazon Machine Image)
with a basic installation of Alaveteli, which you can use to create a running
server on an Amazon EC2 instance. This creates an instance that runs in
development mode, so we wouldn't recommend you use it for a production system
without changing the configuration.

Unfortunately, Alaveteli will not run properly on a free Micro
instance due to the low amount of memory available on those
instances; you will need to use at least a Small instance, which
Amazon will charge for.

The AMI can be found in the EU West (Ireland) region, with the ID ami-23519f54
and name “Basic Alaveteli installation 2014-06-12”. You can launch an instance
based on that AMI with [this
link](https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-23519f54).

When you create an EC2 instance based on that AMI, make sure that you choose
Security Groups that allows at least inbound HTTP, HTTPS, SSH and, if you want
to test incoming mail as well, SMTP.

When your EC2 instance is launched, you will be able to log in as the `ubuntu`
user. This user can `sudo` freely to run commands as root. However, the code is
actually owned by (and runs as) the `alaveteli` user. After creating the
instance, you may want to edit a configuration file to customize the site's
configuration. That configuration file is
`/var/www/alaveteli/alaveteli/config/general.yml`, which can be edited with:

    ubuntu@ip-10-58-191-98:~$ sudo su - alaveteli
    alaveteli@ip-10-58-191-98:~$ cd alaveteli
    alaveteli@ip-10-58-191-98:~/alaveteli$ nano config/general.yml

Then you should restart the Thin webserver with:

    alaveteli@ip-10-58-191-98:~/alaveteli$ logout
    ubuntu@ip-10-58-191-98:~$ sudo /etc/init.d/alaveteli restart

If you find the hostname of your EC2 instance from the AWS console, you should
then be able to see the site at
`http://your-ec2-hostname.eu-west-1.compute.amazonaws.com`

If you have any problems or questions, please ask on the [Alaveteli Google
Group](https://groups.google.com/forum/#!forum/alaveteli-dev) or [report an
issue](https://github.com/mysociety/alaveteli/issues?state=open).

