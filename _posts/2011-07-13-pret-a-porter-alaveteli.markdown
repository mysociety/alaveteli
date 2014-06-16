---
author: sebbacon
comments: true
date: 2011-07-13 10:02:11+00:00
layout: post
slug: pret-a-porter-alaveteli
title: Pret-a-porter Alaveteli
wordpress_id: 21
categories:
- Blog
- Development
- Hosting
---

As part of my recent work on the Alaveteli code, I've needed to repeatedly test it. Currently it's quite complicated installing an Alaveteli website, and I've been having to reinstall from scratch a few times to make sure my test environment is clean.

It seemed a good idea while I was doing this to set up an Amazon Machine Image (AMI). This means that anyone with a correctly set up Amazon Web Services account can get a running Alaveteli server with just a few clicks. Not only does it have the core software deployed, it also comes with a web server and mail server configured, so it should in theory just work out of the box.

{% include image.html url="/assets/img/ec2.png" description="Alaveteli instances running in EC2" width="517"%}

As a nice side-effect, it means I can run the automated tests really quickly by running them on an "xlarge" EC2 instance (which is equivalent to a server with 14Gb of memory).

People thinking of trying out Alaveteli should therefore consider using the AMI to get started quickly; not least because new AWS customers have access to a "[free tier](http://aws.amazon.com/free/)" for a year.

The only down side is that actually getting started with EC2 can be a bit fiddly if you've never done it before.  [Read more about the AMI here](/installing/ami).
