---
author: sebbacon
comments: true
date: 2012-04-16 09:57:00+00:00
layout: post
slug: alavetelicon-community-cakes-and-black-boxes
title: 'Alavetelicon: community, cakes, and black boxes'
wordpress_id: 325
categories:
- Uncategorised
---

[Alavetelicon 2012](http://www.alaveteli.org/about-2/alavetelicon-april-2012/) has finished, the tweeting has subsided, and I think I've just about finished digesting the enormous conference dinner.  It was a lot of fun, with [a host of dedicated FOI activists and hackers](http://www.alaveteli.org/about-2/alavetelicon-april-2012/delegates/) who could only make it thanks to the generous funding provided by [Open Society Foundation](http://www.soros.org/) and [Hivos](http://www.hivos.nl/).

The [schedule was split into streams](http://www.alaveteli.org/about-2/alavetelicon-april-2012/schedule/), and had lots of non-programmed time, so I only actually saw a small part of it.  There are [write-ups](http://www.elvaso.cl/2012/04/alaveteli-conf-2012-otra-comunidad-para-acceso-inteligente) in [various](http://tinyurl.com/7zamxfa) [languages](http://blogs.lanacion.com.ar/data/mundo/conferencia-de-alaveteli-o-de-como-darle-voz-a-la-sociedad-civil/) from other participants; here are some personal observations.



## Building a movement


The main goal of the conference was to strengthen and build the community.  At the time of the conference there were 7 installations of Alaveteli worldwide, but only a small amount interaction between these groups.  So far, I've been the only person with a clear incentive to make sure people collaborate (I'm funded to do it!)  This clearly isn't sustainable; more people need to talk directly to each other.  There's no better way of building trust and understading that meeting face-to-face.[![](http://blogs.mysociety.org/alaveteliorg/files/2012/02/alavetelicon-300x154.jpg)](http://blogs.mysociety.org/alaveteliorg/files/2012/02/alavetelicon.jpg)

This certainly worked well for me.  Of course, I had conversations with people about Freedom of Information and database architectures, but more importantly, I now know who has a new baby daughter, who is thinking about living in a co-housing project, and who loves British 80s electronic sensation _Depeche Mode_.  I was really struck by what a friendly group of people this was.

Richard Hunt, who's leading a project to launch an Alaveteli site in the Czech Republic, had some encouraging things to say about community.  In his eloquent (and very quotable) presentation, he explained his journey towards using Alaveteli.  At first, he wasn't sure about using the software.  He'd talked with developers who had looked at the code, and had felt it might be better to start from scratch.  So Richard contacted developers who had already deployed Alaveteli sites directly, and got lots of very useful, friendly, and encouraging responses.  His conclusion was that Alaveteli isn't just a technical platform; "it is also about people -- their dreams and ambitions of impeccable merit".



<blockquote>For so long it was just a dream and idle talk on our side. Now we are nearly there, and we are part of a BIG movement. Feels great, doesn't it?</blockquote>



This is encouraging, but the conversations started at the conference must continue if they are to bear fruit in the form of more international collaboration.  Please join the new [Alaveteli Users mailing list](http://groups.google.com/group/alaveteli-users), and share ideas or ask questions there!



## The future of Alaveteli



There was a lot of discussion of which new features should be added to Alaveteli next, some of which I've listed on the [alaveteli-dev Google group](http://groups.google.com/group/alaveteli-dev/browse_thread/thread/61ed4070b2db4755).  However, three general themes particularly struck a cord with me:

**1. More collaboration, less confrontation**
In the UK, we have been accused of encouraging [a confrontational, points-scoring approach to FOI](http://2040info.blogspot.co.uk/2012/02/do-they-know-what.html).  At the conference, there were stories of how FOI actually _frees_ people within a bureaucracy to speak directly to the requester -- without having to go via a press office. We heard of various cases where ministries _actively_ wanted to take part in Alaveteli pilots.  In the UK, we have found that FOI officers take their jobs very seriously, and do want to work with the Alaveteli concept; yet they feel that sometimes it makes things unnecessarily hard for them.

I'm not sure what conclusion to take from this, exactly. It remains the case that Alaveteli must be able to deal with obstinate authorities that don't want to play the game, and it is a prime virtue of the system that it remains well outside the bureaucracies that it aims to hold to account.  However, I'm left with a sense that we should examine how we can continue to do this while providing more support to our allies within the System.

**2. Cake and fireworks**
Lots of people at the conference asked for more statistics to be made available on Alaveteli sites.  mySociety has always been a little reluctant to release statistics, because they are so easy to spin or misinterpret.  However, delegates repeatedly referred to their power for campaigning.  The psychological impact of a big red cross next to your organisation's name, which you can remedy through positive action, is a powerful motivator.  One idea that was mooted was to award a real-life prize (a.k.a. [Cake and Fireworks](https://github.com/mysociety/alaveteli/issues/438)) to the "top" authorities in various categories each year.  I think this is a great idea.

**3. Black Box APIs**
[Acesso Inteligente](www.­accesointeligent­e.­org) is an FOI website in Chile that doesn't use Alaveteli.  In Chile, all FOI requests must be made via various different web forms.  Accesso Inteligente is a tremendous technical achievement which automatically posts requests to the correct organisation's form, and "screen scrapes" the results, giving Chilean citizens a uniform interface to make all FOI requests.

The team behind the website would love to use Alaveteli as their front end system.  The concept they've come up with is deceptively simple: repackage their form-posting-and-scraping functionality as a "black box" which acts as if it's an authority that accepts FOI requests by emails, and sends the answers by email.  They can then install Alaveteli without any modifications, and configure it to send FOI requests to the relevant "black box" email addresses.

I love this concept for its simplicity, and I think it can easily be extended to support other use cases.  For example, there's a lot of talk of an Alaveteli system that supports paper requests and responses.  This might best be implemented as a "black box" that receives and sends email, with an implementation that helps a human operator with printing and scanning tasks in the back office.


