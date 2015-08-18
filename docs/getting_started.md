---
layout: page
title: Getting started
redirect_from: /getting_started/
---

# Getting started with Alaveteli

<p class="lead">
  This guide is aimed at people who are thinking about setting up their own
  Alaveteli website in a new jurisdiction.
</p>

For inspiration, take a look at some of the existing Alaveteli websites, like
[tuderechoasaber.es](http://tuderechoasaber.es) (Spain),
[AskTheEU](http://www.asktheeu.org) (EU), or
[WhatDoTheyKnow](https://www.whatdotheyknow.com) (UK). These sites all use the
Alaveteli software, plus their own custom themes installed on top to make them
look different.

You don't even need to make a custom theme to get started. You can have a
website that looks like [the demo website](http://demo.alaveteli.org) and
simply drop in your own logo.

The process of getting your own Alaveteli website up and running could take
anywhere from one day to three months, depending on the scale of your ambition
for customising the software, your access to technical skills, and your
available time.

You can get a feeling for how things might turn out by reading [how an
Alaveteli was set up in
Spain](https://www.mysociety.org/2012/04/16/a-right-to-know-site-for-spain/)
(remember that this was with an experienced developer in charge). You will also
need to think about how you will run the website; a successful Alaveteli
requires lots of ongoing effort to moderate and publicise (see Step 6 and Step
7, below).

Here are the steps we suggest you follow in order to get started.

* [Step zero: assemble your initial team](#step-0)
* [Step one: get a working, uncustomised version running](#step-1)
* [Step two: start to gather data about public authorities](#step-2)
* [Step three: customise the site](#step-3)
* [Step four: translate everything](#step-4)
* [Step five: Test drive the site](#step-5)
* [Step six: Market the website](#step-6)
* [Step seven: Maintain the website](#step-7)


<a name="step-0"> </a>

## Step zero: assemble your initial team

You're unlikely to be able to get much done on your own. You will need
translators, people to hunt down email addresses of authorities, possibly a
designer, and preferably a technical expert to help with customisations. Read
through this guide first, and think about the skills you will need to
successfully launch and maintain the website.

It took about [ten people (including translators) working for three
days](http://groups.google.com/group/alaveteli-dev/msg/1bd4afd3091f8b4f) to
launch [Queremos Saber](http://queremossaber.org.br/), a Brazilian version of
Alaveteli.

> It was really cool setting the site up. And even with some minor
> difficulties (most related to the fact that we had no one really experienced
> with both Ruby on Rails and Postfix) it was pretty quick and in less than a
> week we had a fully featured website!
>
> -- _Pedro Markun, Queremos Saber_

[AskTheEU](http://www.asktheeu.org), a much more complete and polished version with
a custom theme and several other customisations, took a team of 2 or 3 people
about 3 months (part time) to complete.

Ask members of your team to consider joining one of the mailing lists. If you
have any questions, these are the first places to ask.
[alaveteli-users](http://groups.google.com/group/alaveteli-users) is a mailing
list for non-technical users of the software. Post messages there to ask for
advice about getting your project started, questions about how people use the
software, and so on.
[alaveteli-dev](http://groups.google.com/group/alaveteli-dev) is the place to
ask questions of a technical nature, such as problems installing Alaveteli.

<a name="step-1"> </a>

## Step one: get a working, uncustomised version running

You have two options here: install your own copy, or ask the Alaveteli team to
provide a hosted version.

If you install your own copy, you have complete control over the website, its
performance, how often it is upgraded, and so on. We recommend this as the best
approach. However, you will need some resources to do this.

Alternatively, we have very limited capacity to run a handful of Alaveteli
sites for willing volunteers. We want to learn more about how we can support
third parties, and to do so we're happy to help host low-volume sites for two
or three partners. However, you will have no service level agreement, no
warranties, and no guarantee on our time: if the website goes down when we're
on holiday, you'll have to wait until we're back! If you want to try this
route, please [get in touch](mailto:international@mysociety.org) to find out if
we have capacity.

### Install your own copy

You'll need to find a tech person who knows about hosting websites using Apache
and Linux. They don't need to know Ruby on Rails, but it would be a huge
advantage if they do.

You'll also need to source a server. You should ask your tech person to
help with this. The minimum spec for running a low traffic website is
512MB RAM and a 20GB disk. 2GB RAM would be ideal. We recommend the
latest Debian Wheezy (7) 64-bit or Ubuntu precise (12.04)
as the operating system. Rackspace offer suitable cloud servers, which
start out at around $25 / month. Then your tech person should follow the
[installation documentation]({{ page.baseurl }}/docs/installing/).

Alternatively, you could use Amazon Web Services. This has the
added advantage that you can use our preconfigured [Alaveteli EC2
AMI]({{ page.baseurl }}/docs/installing/ami/) to get you
started almost instantly. However, it's more expensive than Rackspace,
especially if you want more RAM.

### Play around with it

You'll need to understand how the website works. Until your own copy is
available, you can try the copy running on the [demo
server](http://demo.alaveteli.org) (though note this isn't guaranteed to be
available or working).

Right now we don't have a guide book, so you'll just have to explore on your
own.

When you have your own version running, try logging into the admin interface by
adding `/admin` onto the end of your domain name. This will take you to the
administrative interface. It's plain and simple, but functional. For example,
try adding new authorities there, perhaps with your own email address, so you
can see what requests look like to them.

When trying things out, you need to wear several hats -- as a site
administrator, an ordinary site user, and as a public authority. This can get
confusing with several email addresses, so one quick and easy way to manage
this is to use a throwaway email service like [Mailinator](http://mailinator.com).

<a name="step-2"> </a>

## Step two: start to gather data about public authorities

One of the most important things you need to do before launching is to gather
together a list of all the bodies to whom you want to address FOI requests.

It's a good idea to make a shared speadsheet that you can ask your supporters
to help fill out. A template like [this Google
spreadsheet](https://docs.google.com/spreadsheet/ccc?key=0AgIAm6PdQexvdDJKdzlNdXEtdjBETi1SLVhoUy1QM3c&hl=en_US) is ideal.

If you email possible supporters asking for help, in addition to helping make
your job easier, it will also help you identify eager people who might be
interested in helping you maintain and run the website. We have written [a
blog post about
this](https://www.mysociety.org/2011/07/29/you-need-volunteers-to-make-your-website-work/).

The admin interface includes a page where you can upload a CSV file (that's a
file containing comma-separated values) to create or edit authorities. CSV is a
convenient format -- for example, it's easy to save data from a spreadsheet as
a CSV file.

<a name="step-3"> </a>

## Step three: customise the site

### Name and social media

Obviously, you'll want to put your own visual stamp on the site. Once you have
a name for your project (e.g., WhatDoTheyKnow in the UK, AskTheEU in the EU,
InformateZyrtare in Kosovo), register a twitter username, and a domain name.
Alaveteli relies on you keeping a blog for its "News" section, so you might
want to consider setting up a free blog at http://wordpress.com or
http://blogger.com and announce your project with a new blog post.

### Branding and theming

Next, think about the visual identity. At a minimum, you should probably
replace the default Alaveteli logo that you can see at the top left of
<http://demo.alaveteli.org>. It's also easy to change the colour scheme.

If you have a bit more budget and time, you can rework the design more, with a
custom homepage, different fonts, etc; however, the more you customise the
site, the harder it is to upgrade in the future; and you'll need a developer
and/or designer to help do these customisations. We call the custom set of
colours, fonts, logos etc a "theme"; there are some notes for developers about
[writing a theme]({{ page.baseurl }}/docs/customising/themes/). You
might spend anywhere between 1 and 15 days on this.

### Legislative differences

We rely on users to help categorise their own requests (e.g., as "successful",
or "refused"). We call these categories "states". Most FOI laws around the
world are sufficiently similar that you can probably use Alaveteli's states
exactly as they come out of the box.

In addition, we have found that it's generally a bad idea to try to implement
laws exactly in the user interface. They are often complicated, and confusing
for users. Since the concept of Alaveteli is to make it easy to exercise the
right to know, we take the view that it's best to implement how a FOI process
*should* be, rather than how it *actually is right now*.

However, if you really feel you need to alter the states that a request can go
through, it is possible to do this to some degree within your theme. Have a
think about what is required, and then send a message to the Alaveteli mailing
list for feedback and discussion. Then you'll need to ask your developer to
implement the new states. It's usually no more than a couple of days' work,
often less. But complicated workflows might take a bit longer.

### Write the help pages

The default help pages in Alaveteli are taken from WhatDoTheyKnow, and are
therefore relevant only to the UK. You should take these pages as inspiration,
but review their content with a view to your jurisdiction. See [the documentation on Alaveteli's themes]({{ page.baseurl }}/docs/customising/themes/#customising-the-help-pages) for details
on which pages are important, and what content they need to have.

The help pages contain some HTML. Your tech person should be able to advise on
this.

Once the pages are written, ask your tech person to add them to your theme.

Now is also a good time to start thinking about some of your standard emails
that you'll be sending out in response to common user queries and
administrative tasks -- for example, an email that you send to IT departments
asking them to whitelist emails from your Alaveteli website (if your emails are
being marked as spam). See the
[Administrator's Manual]({{ page.baseurl }}/docs/running/admin_manual/) for details
on some of the common administrative tasks. There is a list of the
standard emails used by WhatDoTheyKnow on the
[FOI Wiki](http://foiwiki.com/foiwiki/index.php/Common_WhatDoTheyKnow_support_responses).

### Other software customisations

Perhaps you would like a new usability-related feature not in Alaveteli
already, like the automated language detection for multi-language websites; or
Facebook integration; or an iPhone app.

Perhaps you've found an area relating to translations that Alaveteli doesn't
yet support fully (for example, we've not yet needed to implement a site with a
language written right-to-left).

Perhaps your jurisdiction *requires* a new feature not in Alaveteli -- for
example, users may need to send extra information with their requests.

In these cases, you will need to get your tech person (or some other software
developer) to make these changes for you. This can be time consuming; new
software development, testing, and deployment is often complex. You should get
expert advice on the amount of extra time this will require. Typically, changes
like these could add between one and three months onto the project schedule.

<a name="step-4"> </a>

## Step four: translate everything

This is potentially a big job!

If you need to support multiple languages in your jurisdiction, you will need
to translate:

* public authority names, notes, etc
* public authority bodies
* help pages
* all of the web interface instructions in the software

It's a bit easier if you only need to support one language in your
jurisdiction: because you'll already have written the help and public authority
information, you'll only need to translate the web interface.

Public authority names can be edited via the admin interface, or by uploading a
spreadsheet. The help pages need to have one copy saved for each language; your
tech person will put them in the right place.

The web interface translations are managed and collaborated via a website
called <a href="{{ page.baseurl }}/docs/glossary/#transifex" class="glossary__link">Transifex</a>. This website allows teams of translators to collaborate in
one place, using a fairly easy interface.

The Alaveteli page on Transifex is at
<https://www.transifex.com/projects/p/alaveteli/>; the translations all live in a
single translation file called
[`app.pot`](https://www.transifex.com/projects/p/alaveteli/resource/apppot/).

You can set up your language and provide translations there; you can also use
specialise software on your own computer (see the help pages on Transifex)

There are (at the time of writing) around 1000 different sentences or fragments
of sentences (collectively known as "strings") to be translated. The meaning of
many strings should be fairly obvious, but others less so. Until we write a
guide for translators, the best route to take is translate everything you can,
and then ask your tech person or the project mailing list for advice on
anything you're unsure about.

Over time, as bugs are fixed and new features are added, new strings are added
to the file. Therefore, you need to keep an eye on `app.pot` and periodically
review the untranslated strings.

<a name="step-5"> </a>

## Step five: Test drive the site

For launch, the tech person should review the [Production Server Best
Practices]({{ page.baseurl }}/docs/running/server/).

A low-key launch, where you tell just a few trusted people about the site, is a
very good idea. You can then track how things work, and gauge the responses of
authorities. Responses are likely to vary widely between and within
jurisdictions, and the right way of making your website a success will vary
with these responses.

<a name="step-6"> </a>

## Step six: Market the website

In general, the best way to engage authorities is with a mixture of
encouragement and exposure. In private, you can explain that in addition to
helping them meet their legal requirements and civic obligations, you may be
reducing their workload by preventing repeat requests. In public, you can work
with journalists to praise authorities that are doing a good job, and highlight
ones that refuse to take part. It is, therefore, very important to make links
with journalists with an interest in freedom of information.

The other important marketing tool is [Google
Grants](http://www.google.com/grants/), a scheme run by Google that gives free
AdWords to charities in lots of countries around the world. You'll find these
an incredibly useful resource for driving traffic to your site. It's well worth
setting yourself up as a charity if only to take advantage of this programme.

For more ideas, see this [blog post about promoting your Alaveteli site](https://www.mysociety.org/2015/06/02/ten-ways-to-promote-alaveteli-sites/).

<a name="step-7"> </a>

## Step seven: Maintain the website

Running a successful Alaveteli website requires some regular, ongoing input.
This will be easier to do with a small team of people sharing jobs. Hopefully
you have been lucky enough to get funding to pay people to do these tasks.
However, you are also likely to have to rely on volunteers. We've written [a
blog post about the importance of
volunteers](https://www.mysociety.org/2011/07/29/you-need-volunteers-to-make-your-website-work/), which you should read.

You'll need to set up a group email address for all the people who will manage
the website. All site user queries will go here, as will automatic
notifications from Alaveteli. A group address is really useful for helping
coordinate responses, discuss policy, etc.

You could get by with just one or two hours per week. This means keeping an eye
on the "holding pen" of the website, where incoming messages that the site
doesn't know how to handle are stored (things like spam, misaddressed messages,
etc). However, the more effort you put into this, the more successful your
website is. To ensure its success, you should be doing things like:

* Responding to user help enquiries by email
* Monitoring new requests, looking for people who might need help, posting
  encouraging comments on their requests
* Monitoring responses from authorities, looking for ones who are trying to
  refuse to answer, offering advice to the person who made the request, possibly coming up with publicity to "shame" the authority into answering
* Tweeting about interesting requests and responses
* Writing blog posts about the progress of the project
* Communicating with journalists about potentially interesting stories
* Recruiting volunteers to help with the site
* Categorising uncategorised requests

See also the [Administrator's Manual](/docs/running/admin_manual/), which describes
some of the typical tasks you'll need to perform when your site is up and
running.

### What else?

If there's anything you think would be really useful to have in this getting
started guide which is currently missing, let us know so we can add it.
