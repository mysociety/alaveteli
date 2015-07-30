---
layout: page
title: Administrator's guide
---

# Alaveteli administrator's guide

<p class="lead">
  What is it like running an Alaveteli site? This guide explains what you can
  expect, and the types of problem that you might encounter. It includes
  examples of how mySociety manages their own
  <a href="{{ page.baseurl }}/docs/glossary/#foi"
  class="glossary__link">Freedom of Information</a> site, <a
  href="https://www.whatdotheyknow.com">whatdotheyknow.com</a>.
</p>

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
      <li><a href="#rejecting-spam-that-arrives-in-the-holding-pen">Rejecting spam that arrives in the holding pen</a></li>
      <li><a href="#creating-changing-and-uploading-public-authority-data">Creating, changing and uploading public authority data</a></li>
      <li><a href="#banning-a-user">Banning a user</a></li>
      <li><a href="#allowing-a-user-to-make-more-requests">Allowing a user to make more requests</a></li>
      <li><a href="#batch-requests">Batch requests</a></li>
      <li><a href="#resending-a-request-or-sending-it-to-a-different-authority">Resending a request or sending it to a different authority</a></li>
      <li><a href="#hiding-a-request">Hiding a request</a></li>
      <li><a href="#deleting-a-request">Deleting a request</a></li>
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

Administration tasks can be split into [**maintenance**]({{ page.baseurl }}/docs/running/admin_manual/#maintenance) and [**user support**]({{ page.baseurl }}/docs/running/admin_manual/#user-support).
The boundaries of these tasks is in fact quite blurred; the main distinction is
that the former happen exclusively through the web admin interface, whereas the
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

The <a href="{{ page.baseurl }}/docs/glossary/#admin" class="glossary__link">administrative interface</a>
is at the URL `/admin`. Only users who are
<a href="{{ page.baseurl }}/docs/glossary/#admin" class="glossary__link">administrators</a>
can access the admin interface.

To make a user an administrator on a brand new site,
[follow these steps]({{ page.baseurl }}/docs/installing/next_steps/#create-a-superuser-admin-account).

If you're already an administrator, you can grant other users administrator
privilege too. Go to `/admin/users` or click on **Users** at the top of
the admin. Find the user in the list, and click on the name to see the user
details. On that page, click **Edit**. Change the *Admin level* to “super” and
click **Save**.

As well having access to the admin interface, users who are administrators also
have extra privileges in the main website front end. Administrators can:

   * categorise any request
   * view items that have been hidden from the search
   * follow "admin" links that appear next to individual requests and comments

<div class="attention-box warning">
  It is possible completely to override the administrator authentication by
  setting
  <code><a href="{{ page.baseurl }}/docs/customising/config/#skip_admin_auth">SKIP_ADMIN_AUTH</a></code>
  to <code>true</code> in <code>general.yml</code>. Never do this, unless you
  are working on a <a href="{{ page.baseurl }}/docs/glossary/#development"
  class="glossary__link">development</a> server.
</div>

### Removing a message from the holding pen

Alaveteli puts incoming messages (that is,
<a href="{{ page.baseurl }}/docs/glossary/#reponse" class="glossary__link">responses</a>)
into the
<a href="{{ page.baseurl }}/docs/glossary/#holding_pen" class="glossary__link">holding pen</a>
if their `To:` email addresses can't automatically be associated with a
<a href="{{ page.baseurl }}/docs/glossary/#reponse" class="glossary__link">request</a>.

The two most common reasons for this are:

   * the request has closed
   * the email address was wrongly spelled (for example, the sender missed the last
     character off the email address when they copied it)

When this happens, the messages wait in the holding pen until an administrator
redelivers them to the correct request, or else deletes them.

To do this, log into the
The <a href="{{ page.baseurl }}/docs/glossary/#admin" class="glossary__link">admin interface</a>
at `/admin`. If there are any messages in the holding pen, you'll see this
message under the title *Things to do*:

> Put misdelivered responses with the right request

Click on that message &mdash; you'll see a list of all the messages that need
your attention. Click on any one of them to see the details.

<div class="attention-box helpful-hint">
  If the message does not belong to any request, you can delete it instead.
  Simply click on the <strong>Destroy Message</strong> button instead of
  redelivering it.
</div>

When you inspect a message, you may see a guess made by Alaveteli as to which
request the message belongs to. Check this request. If the guess is right
&mdash; the incoming email really is a response to that request &mdash;
the request's *title_url* will already be in the input box: click the
**Redeliver to another request** button.

If there is not a guess, or Alaveteli's guess is wrong, look at the  `To:`
address of the raw email and the contents of the message itself. You need
to figure out which request it belongs to. The special addresses generated by
Alaveteli are of the form:

<pre><code>
[INCOMING_EMAIL_PREFIX]request-[id]-[idhash]@[DOMAIN]
</code></pre>
e.g.
<pre><code>
foi+request-3-691c8388@example.com
</code></pre>

In that form, the first number section after `request-` is the request's <em>id</em>.
You can browse and search
requests in the admin interface by clicking **Requests** at the top of the
admin. When you have found the correct request, copy either its *id* or
its *url_title*.

<div class="attention-box info">
  <p><strong>How to find a request's <em>id</em> or <em>url_title</em></strong></p>
  <p>
    A request's <em>id</em> is the number after <code>/show/</code> in the
    admin interface's URL when you are looking at that request.
    For example, if the URL is <code>/admin/request/show/118</code>, then the
    <em>id</em> is <code>118</code>. Similarly, if you know that you want to see the
    admin interface's page for the request with id <code>118</code>, you know it will
    be <code>/admin/request/show/118</code>.
  </p>
  <p>
    A request's <em>url_title</em> is the part after <code>/request/</code>
    in your Alaveteli site's URL when you are looking at that request.
    In the URL <code>/request/how_many_vehicles</code>, the
    <em>url_title</em> is <code>how_many_vehicles</code>.
  </p>
</div>

Once you have identified the request the message belongs to, return to the
holding pen message page. Find the incoming message's "Actions" and paste the
request *id* or *url_title* into the text input. Click on the **Redeliver to
another request** button.

The message will now be associated with the correct request. It is no longer
in the holding pen, and is shown instead on the public request page.


### Rejecting spam that arrives in the holding pen

Alaveteli maintains a
<a href="{{ page.baseurl }}/docs/glossary/#spam-address-list" class="glossary__link">spam address list</a>.
Any incoming message to an email address on that list
*that would otherwise be put in the holding pen* will be rejected and won't
appear in the admin.

If you see spam messages in the
<a href="{{ page.baseurl }}/docs/glossary/#holding_pen" class="glossary__link">holding pen</a>,
check if they are being sent to a *specific* email address. If they are, that
email address has become a "spam-target" and you should add it to the spam
address list. Thereafter, Alaveteli will automatically reject any messages that
come to that address.

An email address that is not associated with a request (that is, one whose
messages end up in the holding pen) becomes a spam-target once it's been
harvested by spammers. There are several reasons why such an invalid address
might exist &mdash; perhaps it was mis-spelled in a manual reply, for example.
Our experience from running
<a href="{{ page.baseurl }}/docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>
is that you can safely dismiss incoming email to such addresses once they have
been targeted in this way. Legitimate emails that arrive in the holding pen
tend to be unique errors (for example, missing the last character of the email
address due to a cut-and-paste mistake) and the nature of the lifecycle of
requests means they don't typically get used for spam until they are
effectively dead.

To add an email address to the spam address list you need to copy it from an
incoming message and paste it into the spam addresss list. The easiest way to
do this is to click on **Summary** at the top of any admin page, and then click
on **Put misdelivered responses with the right requests** to see the contents
of the holding pen.

<div class="attention-box info">
  If there are no messages in the holding pen, Alaveteli won't show you this
  link. Great &mdash; there are no misdelivered responses needing your
  attention right now!
</div>

Inside the holding pen, you'll see the list of emails awaiting attention
&mdash; click on an email's subject line to see the whole message and its
details. Copy the `To:` email address, then click on the **Spam Addresses**
link under *Actions*. Paste the email address into the text input and click the
**Add Spam Address** button.

You can see the spam address list (that is, all known spam-target email
addresses) at any time by going to the admin interface at `/admin/spam_addresses`.

You can remove any address from the list by clicking the **Remove** button
next to it. Of course, this won't restore any messages that have been
rejected, but Alaveteli will not reject any new messages that are sent to
this address.

Note that if you are seeing consistent spam email in your holding pen, you
should also consider implementing (or increasing) the anti-spam measures
running in your
<a href="{{ page.baseurl }}/docs/glossary/#mta" class="glossary__link">MTA</a>.

### Creating, changing and uploading public authority data

There are three ways to change public authority data on your site:

   * *Create* &mdash;
     You can create a new public authority in the admin interface. Go to **Authorities**, and click the **New Public Authority** button.

   * *Edit* &mdash;
     Once an authority is created, you can update its email address or other
     details by editing it in the admin interface. Go to **Authorities**, find
     the authority you want to update, and click on **edit**.

   * *Upload* &mdash;
     You can also create or edit more than one authority at the same time by
     uploading a file containing the data in comma-separated values (CSV)
     format. This works for new authorities as well as those that already exist
     on your site. Go to **Authorities** and click the **Import from CSV** button. See the rest of this section for more about uploading.

The upload feature is useful &mdash; especially when an Alaveteli site is first
set up &mdash; because it's common to collect data such as the contact details
for the public authorities in a spreadsheet. Alaveteli's upload feature makes it
easy to initially load this data onto the site. It also lets you update the
data if it changes after it's already been loaded.

To use the data in the spreadsheet to update the bodies on your site, export
("save as") the spreadsheet as a CSV file. This is the file you can upload.

The first line of your CSV file should start with `#` (this indicates that this
line does not contain data) and must list the column names for the data that
follows on the subsequent lines. Column names must:

   * be on the first line
   * match expected names *exactly*, and include `name` and `request_email`
    (see table below)
   * appear in the same order as corresponding items in the lines of data that follow

Most spreadsheet programs will produce a suitable CSV file for you, provided
that you carefully specify correct titles at the top of each column. Be sure to
use names exactly as shown &mdash; if Alaveteli encounters an
unrecognised column name, the import will fail.

<table class="table">
  <tr>
    <th>column name</th>
    <th>i18n suffix?</th>
    <th>notes</th>
  </tr>
  <tr>
    <td><code>name</code></td>
    <td><em>yes</em></td>
    <td>
      <em>This column <strong>must</strong> be present.</em><br>
      The full name of the authority.<br>
      If it matches an existing authority's name, that authority will be
      updated &mdash; otherwise, this will be added as a new authority.
    </td>
  </tr>
  <tr>
    <td><code>request_email</code></td>
    <td><em>yes</em></td>
    <td>
      <em>This column <strong>must</strong> be present,
      but can be left empty.</em><br>
      The email to which requests are sent
    </td>
  </tr>
  <tr>
    <td><code>short_name</code></td>
    <td><em>yes</em></td>
    <td>Some authorities are known by a shorter name</td>
  </tr>
  <tr>
    <td><code>notes</code></td>
    <td><em>yes</em></td>
    <td>Notes, displayed publicly (may contain HTML)</td>
  </tr>
  <tr>
    <td><code>publication_scheme</code></td>
    <td><em>yes</em></td>
    <td>
      The URL of the authority's
      <a href="{{ page.baseurl }}/docs/glossary/#publication-scheme" class="glossary__link">publication scheme</a>,
      if they have one
    </td>
  </tr>
  <tr>
    <td><code>disclosure_log</code></td>
    <td><em>yes</em></td>
    <td>
      The URL of the authority's
      <a href="{{ page.baseurl }}/docs/glossary/#disclosure-log" class="glossary__link">disclosure log</a>,
      if they have one
    </td>
  </tr>
  <tr>
    <td><code>home_page</code></td>
    <td>no</td>
    <td>The URL of the authority's home page</td>
  </tr>
  <tr>
    <td><code>tag_string</code></td>
    <td>no</td>
    <td>separated tags with spaces</td>
  </tr>
</table>

   * Existing authorities cannot be renamed by uploading: if you need to do
     this, use the admin interface to edit the existing record first, and
     change its name in the web interface.
   * If the authority already exists (the `name` matches an existing authority's
     name exactly), a blank entry leaves the existing value for that column
     unchanged &mdash; that is, that item of data on your site will not be
     changed. This means you only really need to include data you want to
     update.
   * Columns with "i18n suffix" can accept
     <a href="{{ page.baseurl }}/docs/glossary/#i18n" class="glossary__link">internationalised</a>
     names. Add a full stop followed by the language code, for example:
     `name.es` for Spanish (`es`). This *must* be a locale you've declared in
     [`AVAILABLE_LOCALES`]({{ page.baseurl }}/docs/customising/config/#available_locales).
     If you don't specify an i18n suffix, the default language for your site is
     assumed.
   * You can specify a blank entry in the CSV file by having no character
     between commas.
   * If an entry contains a comma, enclose it in double quotes like this:
     `"Comma, Inc"`.
   * If an entry contains any double quotes, you must replace each of
     them with two (so `"` becomes `""`) and also enclose the whole entry in
     double quotes like this: `"In ""quotes"""` (which will be imported as `In
     "quotes"`).

For example, here's data for three authorities in CSV format ready for upload.
The first line defines the column names, then the next three lines contain the
data (one line for each authority):

    #name,short_name,short_name.es,request_email,notes
    XYZ Library Inc.,XYZ Library,XYX Biblioteca,info@xyz.example.com,
    Ejemplo Town Council,,Ayuntamiento de Ejemplo,etc@example.com,Lorem ipsum.
    "Comma, Inc.",Comma,,comma@example.com,"e.g. <a href=""x"">link</a>"

Note that, if Ejemplo Town Council already exists on the site, the blank entry
for `short_name` will leave the existing value for that column unchanged.

To upload a CSV file, log into the admin and click on **Authorities**. Click on
**Import from CSV file**, and choose the file you've prepared.

Specify **What to do with existing tags?** with one of these options:

   * *Replace existing tags with new ones* <br/>
     For each authority being updated, all existing tags will be removed, and
     replaced with the ones in your CSV file.

   * *Add new tags to existing ones* <br/>
     Existing tags will be left unchanged, and the tags in your CSV file will
     be added to them.

You can add a **Tag to add entries to / alter entries for**. This tag will
be applied to every body that is imported from your CSV file.

We always recommend you click **Dry run** first -- this will run through the
file and report the changes it will make in the database, *without actually
changing the data*. Check the report: it shows what changes would be made if
you really uploaded this data, followed by a message like this:

    Dry run was successful, real run would do as above.

If you see nothing above that line, it means the dry run has resulted in no
proposed changes.

If everything was OK when you ran the dry run, click **Upload** instead. This
will repeat the process, but this time it will make the changes to your
site's database.

If you see an error like `invalid email`, either you really have mistyped an
email address, or (more likely) your CSV file does not have a `request_email`
column.

#### Creating a spreadsheet of existing authorities

You can easily create a spreadsheet containing the authorities that <em>already
exist</em> on your site. Combined with the upload feature described above, this
may be a more convenient way to update your data than editing it in the admin
interface.

To export the existing authorities' data, go to your site's home page (not the
admin) and click <strong>View Authorities</strong>. Then click <strong>List of
all authorities (CSV)</strong> to get a CSV file. You can then make changes to
this file using a spreadsheet program and upload it as described above.

You'll need to remove some columns that are not accepted by the import feature
and possibly rename some that are &mdash; see the column names above.
Also, note that by default the exported spreadsheet does not contain a
`request_email` column. If you want to update email addresses, you should
manually add a column to your spreadsheet with the heading `request_email` and
fill in a new email address for each authority you want to update. Authorities
with blank values in any column will keep their existing value for that
attribute.

<div class="attention-box info">
Alaveteli never includes authorities which have the tag <code>site_administration</code> when it exports authorities in CSV format.
If you're running a development server with the sample data, the single example
body called "Internal admin authority" has this tag, so if you click
<strong>List of all authorities (CSV)</strong>, you'll get a CSV file which
contains no data. You need to add your own authorities (without the
<code>site_administration</code> tag) before you can export them.
</div>

### Banning a user

You may wish to completely ban a user from the website (such as a spammer or troll for example). You need to log into the admin interface at `/admin`. On the top row of links, locate and click on ‘Users’.

Find the user you wish to ban on the list and click on their name. Once on the user page, select ‘edit’.

Enter some text in the in the ‘Ban text’ box to explain why they have been banned.  Please be aware, this is publicly viewable from the users' account. Then click on save and the user will be banned.

### Allowing a user to make more requests

Alaveteli has a config setting <code><a href="{{ page.baseurl }}/docs/customising/config/#max_requests_per_user_per_day">MAX_REQUESTS_PER_USER_PER_DAY</a></code>,
which determines the maximum number of requests that a normal user can
make in a day. If they try to make more than this number of requests
within a 24 hour period, they will see a message telling them that they
have hit the limit, and encouraging them to use the contact form if they
feel they have a good reason to ask for the request limit to be lifted.

To lift the request limit for a particular user, go to the <a href="{{ page.baseurl }}/docs/glossary/#admin" class="glossary__link">admin
interface</a>, click on **Users**, then click on the name of the user
you want to lift the request limit for. Click the **Edit** button. Tick
the checkbox **No rate limit**, and click the **Save** button.

### Batch requests

Sometimes a user may want to send the same request to more than one authority, which we call a batch request. By default, Alaveteli does not allow users to make batch requests.

<div class="attention-box info">
<p>We believe that batch requests can be abused &mdash; users can send poorly thought-out or vexatious requests, which will annoy authorities and damage the reputation of your site. However, well thought-out batch requests can be an extremely useful tool in collecting comparative data sets across types of authority, for example, all police forces.</p>
<p>
We recommend that you enable batch requesting for users who you notice making the same good request to multiple authorities.
</p>
<p>
Users can choose which authorities to include in a batch requests. They  can even send a request to <em>every single authority</em> on your site. Only give this power to users that you trust.
</p>
</div>

To enable batch requests on your site, first you must set
<code><a href="{{ page.baseurl }}/docs/customising/config/#allow_batch_requests">ALLOW_BATCH_REQUESTS</a></code>
to <code>true</code> in <code>general.yml</code>.

This does not allow anyone to make batch requests yet. You must still
enable this for each user on an individual basis. To do this, go to the
<a href="{{ page.baseurl }}/docs/glossary/#admin"
class="glossary__link">admin interface</a>, click on **Users**, then
click on the name of the user who wants to make batch requests. Click
the **Edit** button. Tick the checkbox **Can make batch requests**, and
click the **Save** button.

If you've enabled batch requests for a user, when they start to make a
request, in addition to the box where they can select an authority, they
will see a link to "make a batch request". When the request is sent,
Alaveteli will make a request page for this request for each authority,
as if the user had made individual requests.

### Resending a request or sending it to a different authority

If you have corrected the email address for an authority, you can resend
an existing request to that authority to the new email address. Alternatively,
a user may send a request to the wrong authority. In that situation, you can
change the authority on the request and then resend it to the correct authority.
For instructions, see
[resending a request or sending it to a different authority]({{ page.baseurl }}/docs/running/requests/#resending-a-request-or-sending-it-to-a-different-authority).


### Hiding a request

If a request contains vexatious or inappropriate content, is libellous, or is
not a valid
<a href="{{ page.baseurl }}/docs/glossary/#foi" class="glossary__link">Freedom of Information</a>
request at all, you may want to hide it. A hidden request is still visible to
you and the other administrators, and (optionally) the requester themselves.
For instructions, see
[hiding a request]({{ page.baseurl }}/docs/running/requests/#hiding-a-request).

Responses to a hidden request will be accepted in the normal way, but because
they are added to the request's page, they too will be hidden.

### Deleting a request

You can delete a request from the site. For instructions, see
[deleting a request]({{ page.baseurl }}/docs/running/requests/#deleting-a-request).

Responses to a deleted request will be sent to the holding pen.

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

