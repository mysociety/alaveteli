---
layout: page
title: Administrator's guide
---

# Alaveteli administrator's guide

<p class="lead">
  What is it like running an Alaveteli site? This guide explains what you can
  expect, and the types of problem that you might encounter. At mySociety,
  we've been running our own <a href="/docs/glossary/#foi"
  class="glossary__link">Freedom of Information</a> site, <a
  href="https://www.whatdotheyknow.com">whatdotheyknow.com</a>, since 2008,
  so we've included lots of examples from our own experience.
  
</p>

<div class="attention-box helpful-hint">
  <p>
    <b>Before you start...</b>
    This admin guide assumes your Alaveteli site is already up and running.
    If it's not, you need to follow the steps for
    <a href="{{ site.baseurl }}docs/getting_started/">getting started with Alaveteli</a>.
  </p>
</div>

In this guide:

<ul class="toc">
  <li><a href="#whats-involved">What's involved?</a></li>
  <li><a href="#user-support">User support</a>
    <ul>
      <li><a href="#dealing-with-email-thats-not-getting-through-to-the-authority">Dealing with email that's not getting through to the authority</a></li>
      <li><a href="#requests-to-take-down-information">Requests to take down information</a></li>
      <li><a href="#incorrectly-addressed">Incorrectly addressed</a></li>
      <li><a href="#wants-advice">Wants advice</a></li>
      <li><a href="#general-assistance-required">General assistance required</a></li>
      <li><a href="#vexatious-users">Vexatious users</a></li>
      <li><a href="#mail-import-errors">Mail import errors</a></li>
    </ul>
  <li><a href="#maintenance">Maintenance</a></li>
    <ul>
      <li><a href="#administrator-privileges-and-accessing-the-admin-interface">Administrator privileges and accessing the admin interface</a></li>
      <li><a href="#removing-a-message-from-the-holding-pen">Removing a message from the 'Holding Pen'</a></li>
      <li><a href="#editing-and-uploading-public-body-email-addresses">Editing and uploading public body email addresses</a></li>
      <li><a href="#banning-a-user">Banning a user</a></li>
      <li><a href="#deleting-a-request">Deleting a request</a></li>
      <li><a href="#hiding-a-request">Hiding a request</a></li>
      <li><a href="#hiding-an-incoming-or-outgoing-message">Hiding an incoming or outgoing message</a></li>
      <li><a href="#editing-an-outgoing-message">Editing an outgoing message</a></li>
      <li><a href="#hiding-certain-text-from-a-request-using-censor-rules">Hiding certain text from a request</a></li>
    </ul>
  </li>
</ul>

## What's involved?

The overhead in managing a successful FOI website is quite high. Richard, a
volunteer, wrote a [blog
post](https://www.mysociety.org/2009/10/13/behind-whatdotheyknow/) about some of
this in 2009.

WhatDoTheyKnow usually has about 3 active volunteers at any one time managing
the support, plus a few other less active people who help out at different
times.

Administration tasks can be split into [**maintenance**]({{ site.baseurl }}docs/running/admin_manual/#maintenance) and [**user support**]({{ site.baseurl }}docs/running/admin_manual/#user-support).
The boundaries of these tasks is in fact quite blurred; the main distinction is
that the former happen exclusively through the web 
<a href="{{ site.baseurl }}docs/glossary/#admin" class="glossary__link">admin interface</a>, whereas the
latter are mediated by email directly with end users (but often result in
actions through the web admin interface).

In one randomly chosen week in December 2010, the support team acted on 66
different events, comprising 44 user **support** emails and 22 **maintenance**
tasks.

Most of the support emails require some time to investigate; some (e.g. those
with legal implications) require quite a lot of policy discussion and debate in
order to address them. Maintenance tasks tend to be much more straightforward
to address, although sometimes they need expert knowledge (e.g. about mail
server bounce messages).

During that week, the tasks broke down as follows:

### Regular maintenance tasks

* 18 misdelivered / undelivered responses (a.k.a. the "Holding Pen")
* 4 requests that are unclassified 21 days after response needing classification
* 2 requests that have been marked as needing admin attention
* 2 things marked as errors (message refused by server - spam, full mailbox, etc) to fix

### User support tasks

* 16 general, daily admin: i.e. things that resulted in admin actions on the
  site (bounces, misdelivered responses, etc)
* 14 items wrongly addressed (i.e. to the support team rather than an authority)
* 6 users needed support using the website (problems finding authorities, or authorities having problems following up)
* 4 users wanted advice about FOI or data protection
* 3 requests to redact personal information
* 2 requests to redact defamatory information

## User support

There follows a breakdown of the most common kinds of user support. It's
intended for use as a guide to the kind of policies and training that a support
team might need to develop.

### Dealing with email that's not getting through to the authority

Emails may not get through to the authority in the first place for a few
reasons:

* The recipient's domain has marked the email as spam and not sent it on
* It's gone into the recipient's spam folder due to their own mail client setup
* The recipient has a mail filter configured in their client that otherwise skips their inbox

The first reason is the most common. The solution is to send a standard email
to the recipient's IT department to whitelist email from your service (and of
course send a message to the original recipient about this). The Alaveteli
admin interface also has an option to "resend" any particular message.

An Alaveteli administrator will typically only become aware of this when a
request has become very overdue without any correspondence at all from the
authority. Sometimes the authority's mail server will bounce the email, in
which case it appears in the administrative interface as "needs admin
attention".

### Requests to take down information

#### Legal action

This is where someone tells us that information on the site might be subject to
legal action. The scenario will vary wildly across different legal
jurisdictions. In the UK, this kind of request is most likely to be related to
defamation.

##### Action

* Get the notification by email to a central support email address, so there is
  a written record
* Act according to standard legal advice (e.g. you may need to temporarily take
  down requests while you debate it, even if you think they should stay up; or
  you may be able to redact them temporarily rather than take them down)
* Centrally log the entire conversation and the actions you have taken
* Get further legal advice where necessary.  For example, you may get a risk
  assessment that suggests you can republish the request, or show it with
  limited redactions.

#### Copyright / Commercial

Public authorities who have not quite understood that their responses are
public sometimes don't like this, and claim copyright. Occasionally other
copyright assertions are made about content, but this is the most common one.
"Commercially sensitive" data might also be considered private information.

##### Action

* In the case of threatened legal action, see above.
* Otherwise, in the first instance, treat this as an advocacy case, on the
  basis that FOI requests can be made repeatedly by anyone, the data should be
  public anyway, and publishing it should actually save the authority money.

##### Example email to authority

> As I'm sure you know, our Freedom of Information law is "applicant blind",
> so anyone in the world can request the same document and get a copy of it.
> To save tax payers' money by preventing duplicate requests, and for good
> public relations, we'd advise you not to ask us to take down the
> information or to apply for a license. I would also note that
> &lt;authority_name&gt; has allowed re-use of FOI responses through our
> website since last year, without any trouble.


#### Personal data

This includes everything from inadvertently revealed personal data such as
personally identifying information about benefits claimants to the name of a
user of the site who later develops "Google remorse".

##### Action

* Assess request, with reference to local Data Protection laws.  Don't
  automatically presume in favour of taking something down, but weighing the
  nuisance/harm caused to the individual which would be relieved by taking the
  material down against the public interest in publishing / continuing to
  publish the material.  "Sensitive" personal data will typically require a
  much higher level of public interest.
* [WhatDoTheyKnow considers](https://www.whatdotheyknow.com/help/privacy#takedown) there to be a
  strong public interest in retaining the names of officers or servants of
  public authorities
* For users who want their name removed entirely from the site, in the first
  instance, try to persuade them not to do so:
* Find out why they want their name removing
* Explain that the site is a permanent archive, and it's hard to remove things
  from the Internet once posted
* Find examples of valuable requests they've made, to show why we want to keep
  it
* Explain technical difficulties of removal (if relevant)
* With persistent requests, consider changing their account name to abbreviate
  their first name to an initial, as this won't confuse existing requests too
  much.  Where there are grounds of personal safety, name should be removed and
  replaced with suitable redaction text.
* Where redaction is hard (e.g. removing a scanned signature from a PDF, ask
  them to resend their response with redaction in place.  This has a benefit of
  training them not to do this in the future, which is a good thing.
* Where redactions take place, it is advisable to add an annotation to the
  request


### Incorrectly addressed

Emails that arrive at the support team address, but shouldn't have.  Two main types:

* Users who think the site is a place to contact agencies directly (e.g. people
  going though immigration and asylum processes who want to contact the UK
  Borders Agency)
* Users who email the support email address rather than using the online form;
  usually because they've replied to a system email rather than followed the
  link in the message

#### Action

Respond to user and point them in the right direction.

##### Example message:

> I like to know some information about my EEA2 application which i applied on
> july 2010.i do not get any response yet ...please let me know what i will do.

##### Example response:

> You have written to the team responsible for the WhatDoTheyKnow.com website;
> we only run that website and are not part of the UK Government.
>
> As you are asking about your own personal circumstances you need to contact
> the UKBA directly; their contact information is available at:
>
> http://www.bia.homeoffice.gov.uk/contact/contactspage/
> http://www.ukba.homeoffice.gov.uk/contact/contactspage/contactcentres/
>
> You might also want to consider contacting your local MP.  You could ask your
> local council or the Citizens Advice Bureau if there is an immigration advice
> centre where you are.

##### Example message:

>  is the greenwaste collection paying for its self? .i suspect due to
>  the low numbers of residents taking up the scheme, what is the true
>  cost of these collections? is the scheme liable to be scrapped ?

##### Example response:

>  You've written to the team responsible for the website WhatDoTheyKnow.com
> and not &lt;authority_name&gt;
>
> If you want to make a freedom of information request to them you can do so,
> in public, via our site. To get started click "make a new freedom of
> information request" at:
>
> https://www.whatdotheyknow.com/body/&lt;authority_name&gt;

### Wants advice

Two common examples are:

* A user isn't sure where to direct their request
* Wants to know the best way to ask an authority for all the personal data they
  hold about themselves

##### Example request:

> I would like to know at this stage under the freedom act can ask
> directly to UK embassies or high commission abroad to disclose some
> information. or I have to contact FCO through this website.

##### Example response:

> I would suggest making your request to the FCO as they are they body
> technically subject to the Freedom of Information Act.
>
> When you make your request it will be sent to the FCO's central FOI team they
> will then co-ordinate the response with the relevant parts of their
> organisation.


### General assistance required

Can be for many reasons, e.g.

* They had withdrawn their request, and an authority had subsequently
  replied, marking the request as open again.
* Suggested corrections to authority names / details from users or authorities
  themselves
* A reply has been automatically filed under the wrong request

### Vexatious users

Some users persistently misuse the website. An alaveteli site should have a
policy on banning users, for example giving them a first warning, informing
them about moderation policy, etc.

### Mail import errors

These are currently occurring at a rate of about two a month. Sometimes the
root cause seems to be blocking in the database when two mails are received for
the same request at about the same time, sometimes it just seems to be IO
timeout if the server is busy. When a mail import error occurs, the mail
handler (Exim) is sent an exit code of 75 and so should try to deliver the mail
again. A mail is sent to the support address for the site, indicating that an
error occurred, with the error and the incoming mail as attachments. Usually
Exim will redeliver the mail to the application. On the rare occasion it
doesn't, you can import it manually, by putting the raw mail (as attached to
the error sent to the site support address) in a file without the first "From"
line, and piping the contents of that file into the mail handling script. e.g.
```cat missing_mail.txt | script/mailin```


## Maintenance

### Administrator privileges and accessing the admin interface

The administrative interface is at the URL `/admin`.

Only users with the `super` admin level can access the admin interface. Users
create their own accounts in the usual way, and then administrators can give
them `super` privileges.

There is an emergency user account which can be accessed via
`/admin?emergency=1`, using the credentials `ADMIN_USERNAME` and
`ADMIN_PASSWORD`, which are set in `general.yml`.  To bootstrap the
first `super` level accounts, you will need to log in as the emergency
user. You can disable the emergency user account by setting `DISABLE_EMERGENCY_USER` to `true` in `general.yml`.

Users with the superuser role also have extra privileges in the website
front end, such as being able to categorise any request, being able to view
items that have been hidden from the search, and being presented with "admin"
links next to individual requests and comments in the front end.

It is possible completely to override the administrator authentication by
setting `SKIP_ADMIN_AUTH` to `true` in `general.yml`.

### Removing a message from the 'Holding Pen'

The reason a message is in the holding pen is because the email can't be automatically associated with the request it is responding to. The email needs to be moved from the holding pen to the request it belongs with.

First, log into the admin interface at `/admin`. You will see messages that are in the 'holding pen' under the title ‘Put misdelivered responses with the right request’. Click on the chevron to see the individual messages.

If you click on a message in the holding pen, you may see a guess made by Alaveteli as to which request the message belongs to. Check this request. If it isn't the right one, or if Alaveteli hasn't made any guesses, you will need to look at the `To:` address of the raw email and the contents of the mail in order to figure out which request it belongs to. You can browse and search requests in the admin interface under the 'Requests' menu item.

Once you have identified the request the message belongs to, you need to go back to the holding pen message page. Paste the request `id` or `url_title` into the box under 'Actions' in 'Incoming Message'. The request `id` can be found in the request URL in the admin interface - it is the part after `/show/`. In the admin request URL `/admin/request/show/118`, the request `id` is `118`. The `url_title` can be found in the request URL in the main interface - it is the part after `/request/`. In the URL `/request/documents_relating_to_meeting`, it is `documents_relating_to_meeting`. Then click on 'Redeliver to another request'.

The message will now be associated with the correct request and will appear on the public request page.

### Editing and uploading public body email addresses



### Banning a user

You may wish to completely ban a user from the website (such as a spammer or troll for example). You need to log into the admin interface at `/admin`. On the top row of links, locate and click on ‘Users’.

Find the user you wish to ban on the list and click on their name. Once on the user page, select ‘edit’.

Enter some text in the in the ‘Ban text’ box to explain why they have been banned.  Please be aware, this is publicly viewable from the users' account. Then click on save and the user will be banned.

### Deleting a request

You can delete a request entirely using the admin interface. You will mainly only need to do this if someone has posted private information. Go to the admin page for the request by searching or browsing in the 'Requests' section of the admin interface. In the first section, click the 'Edit metadata' button. At the bottom of the next page, click the red 'Destroy request entirely' button.

### Hiding a request

You can hide an entire request from the admin interface. Log in to the
admin interface at `/admin`. On the top row of links, locate and click on
'Requests'. Search or browse to find the admin page for the request you
want to hide. You can also go directly to this page by following an
'admin' link from the public request page. You can hide a request in one
of two ways.

  * <strong>Hiding a vexatious or non-FOI request and notifying the
    requester</strong>
    Scroll down to the 'actions' section of the request
    admin page. Select one of the options next to 'Hide the request and
    notify the user:' and customise the text of the email that will be
    sent to the user to let them know what you've done. When you're
    ready, click the 'Hide request' button.
  * <strong>Hiding a request or making it only visible to the
    requester without notifying the requester</strong>
    In the 'Request metadata' section of the request
    admin page, click 'Edit metadata'. Change the 'Prominence' value to
    'requester_only' to only allow the requester to view the request, or
    to 'hidden' to hide the request from everyone except site admins.
    When you're ready, click 'Save changes' at the bottom of the 'Edit
    metadata' section. No email will be sent to the requester to notify
    them of what you've done.

### Hiding an incoming or outgoing message

You may need to hide a particular incoming or outgoing message from a
public request page, perhaps because someone has included personal
information in it. You can do this from the message's page in the admin
interface. You can get to a message's admin page either by following the
links from the "Outgoing messages" or "Incoming messages" sections of
the request's admin page, or directly from the public request page by
clicking on the 'admin' link on the message itself. Once you are on the
message's admin page, you can change it's prominence. Set the prominence
to 'hidden' to hide it from everyone except site admins, or to
'requester_only' to allow it to be viewed by the requester (and by site
admins). If you can, add some text in the box 'Reason for prominence'.
This will be displayed as part of the information that will appear on
the request page where the message used to be, telling people that it
has been hidden.

### Editing an outgoing message

You may find there is a need to edit an outgoing message because the requester has accidentally included personal information that they don't want to be published on the site. You can either follow one of the 'admin' links from the public request page on the site, or find the request from the admin interface by searching under 'Requests'.

Scroll down to the 'Outgoing Messages' section, and click on 'Edit'.

Then on the next page you will be able to edit the message accordingly and save it. The edited version will then appear on the Alaveteli website, although an unedited version will have been sent to the authority.


### Hiding certain text from a request using censor rules

Censor rules can be attached to a request or to a user. These rules define bits of text
to be removed (either from the request (and all associated files e.g. incoming
message attachments) or from all requests associated with a user), and some
replacement text. In binary files, the replacement text will always be a series
of 'x' characters identical in length to the text replaced, in order to
preserve file length. The attachment censoring does not work consistently, as
it is difficult to write rules that will match the exact contents of the
underlying file, so always check the results. Make sure to also add censor
rules for the real text and check the "View as HTML" option; this is currently
(Sept 2013) generated from the uncensored PDF or other binary file.

You can make a censor rule apply as a [regular
expression](http://en.wikipedia.org/wiki/Regular_expression) by checking the
"Is it regexp replacement?" checkbox in the admin interface for censor rules.
Otherwise it will literally just replace any occurrences of the text entered.
Like regular text-based censor rules, regular expression based rules will be
run over binary files related to the request too, so a regular expression that
is quite loose in what it matches may have unexpected consequences if it also
matches the underlying sequence of characters in a binary file. Also, complex
or loose regular expressions can be very expensive to run (in some cases
hanging the application altogether), so please:

* Restrict your use of them to cases that can't otherwise be easily covered.
* Keep them as simple and specific as possible.

<strong>To attach a censor rule to a request</strong>, go to the admin page for the
request, scroll to the bottom of the page, and click the "New censor
rule (for this request only)" button. On the following page, enter the
text that you want to replace e.g. 'some private info', the text you
wish to replace it with e.g. '[private info has been hidden]', and a
comment letting other admins know why you have hidden the information.

<strong>To attach a censor rule to a user</strong>, so that it will be applied to all
requests that the user has made, go to the user page in the admin
interface. You can do this either by clicking on the admin heading
'Users' and browsing or searching to find the user you want, or by
following an 'admin' link for the user from the public interface. One
you are on the admin page for the user, scroll to the bottom of the page
and click the 'New censor rule' button. On the following page, enter the
text that you want to replace e.g. 'my real name is Bruce Wayne', the
text you wish to replace it with e.g. '[personal information has been
hidden]', and a comment letting other admins know why you have hidden
the information.


