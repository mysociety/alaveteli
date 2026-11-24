---
layout: page
title: Data privacy - hiding or removing information
---

# Data privacy: hiding or removing information

<p class="lead">
  Your Alaveteli site first and foremost publishes requests and responses,
  but there are circumstances when you will need to hide information too.
  This page summarises what you might need to do, and how Alaveteli
  supports it.
</p>

We know from our own experience running
<a href="{{ page.baseurl }}/docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>
in the UK that it is sometimes necessary to remove information from the site.
Furthermore, sometimes this needs to be done sensitively, swiftly, and
transparently.

This is particularly relevant to sites running in countries with strong privacy
laws such as the EU GDPR, where you may need to hide or delete personal information
to comply with the law.

This page provides an overview of the ways you can hide or remove things from
your Alaveteli site, and some reasons why you might need to.

It is also useful to developers, as it defines some of the vocabulary used in
the code base.

## Hiding, deleting, erasing, editing & redacting

There are different approaches to removing information on your site, in increasing
order of intensity:

* **Hiding** keeps the data, but does not display it. Administrators (and,
  optionally, the user who made a request that has been hidden) can still
  access hidden the content. [more...](#how-hiding-works-prominence)

* **Redacting** is the _automated_ hiding of content based on pattern-matching
  (for example, hiding all occurrences of a particular bank account number).
  Alaveteli has two mechanisms for this: text masks and censor rules.
  [more...](#redacting)

* **Editing** lets an administrator change text in messages. Unlike redacting,
  editing actually removes the original information. [more...](#editing-a-message)

* **Erasing** removes the content of a message (sender, subject, body, attachments)
  but keeps some metadata (dates) to show that a message was sent (or received).
  [more...](#erasing-a-message)

* **Deleting (or destroying)** removes the item completely. This makes sense for spam, but
  generally we recommend hiding rather than deleting content. This is also
  called *destroying* in Alaveteli. [more...](#deleting)

## Two important types of removal

There are two particular circumstances where removal of information is required
and may need special handling.

### Takedown requests

Because your Alaveteli site automatically publishes messages, sometimes it will
display information that someone feels should be taken down. They will contact
you demanding or appealing for its removal: this is a
<a href="{{ page.baseurl }}/docs/glossary/#takedown" class="glossary__link">takedown request</a>,.
The automatic way Alaveteli publishes messages, combined with the nature of
Freedom of Information work, means that takedown requests often do have merit.
Part of the role of your admin team is to handle them quickly and fairly.
Furthermore, the details of specific cases can sometimes be complicated, and
may have legal implications &mdash; for example, if the information is
libellous or contravenes local laws.

We recommend you have a process in place for handling these events when they
occur. The team that runs
<a href="{{ page.baseurl }}/docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>
in the UK responds to each takedown request in this way:

* hide the message or request if it's clear the correspondence is clearly inappropriate
* if information has been hidden, let the person who requested the takedown know that the
  information has been hidden pending a decision by your admin team
* hide, delete, restore or keep the information hidden, depending on the outcome of
  the admin decision

### Accidental releases of data

Another situation which sometimes arises when running an Alaveteli site is the
inadvertent release of data. This is where a
<a href="{{ page.baseurl }}/glossary/#body" class="glossary__link">body</a>
accidentally includes sensitive data as part of their response. When this does
happen, it is often in the attachments (such as spreadsheets). The nature of
these accidental releases can sometimes be very serious, because often the
source of the data is an official body whose data may be sensitive.

When this happens, you should hide the data immediately and review the
situation. You may be guided to some extent by the local law. For example, in
the UK, we report any such incidents to the Information Commissioner. Sometimes
the inadvertently released data is not sensitive, and publication of it may be
in the public interest. These are decisions that your admin team will need to
make, taking any legal implications into consideration.

Often, where data has been included in a response by accident, the body will
provide a corrected replacement response &mdash; and perhaps the ombudsman or
information commissioner has been notified &mdash; it might be necessary (and
possibly a legal obligation) to _delete_ the material from both the site and
the server.

## How hiding works: prominence

Alaveteli displays things depending on their _prominence_. When you hide
requests or responses, you do so by changing their prominence, which you can do
in the
<a href="{{ page.baseurl }}/docs/glossary/#admin_interface" class="glossary__link">admin interface</a>. Changing the prominence of an item never deletes any information.

You can set the prominence for a whole page (that is, a request and any
messages, including responses associated with it), or any individual message.

<table class="table">
  <tr>
    <th>
      Prominence
    </th>
    <th>
      Effect
    </th>
  </tr>
  <tr>
    <td>
      normal
    </td>
    <td>
      The item is displayed.
    </td>
  </tr>
  <tr>
    <td>
      backpage
    </td>
    <td>
      <em>(only applicable to a whole page)</em>
      <br>
      The page is displayed, but is never included in lists of requests or
      search results on the site.
      <br>
      This discourages people from finding a request, but they can access it if
      they have the URL.
      <br>
      It also sets an <code>X-Robots-Tag: noindex</code> header to prevent the
      request being indexed by external search engines.
      <br>
      Messages <em>within</em> this page can themselves be hidden.
    </td>
  </tr>
  <tr>
    <td>
      hidden
    </td>
    <td>
      The item is not displayed.
      <br>
      Instead, a message such as "This message has been hidden"* is shown,
      followed by a specific reason for it having been hidden if the
      administrator has provided one.
    </td>
  </tr>
  <tr>
    <td>
      requester_only
    </td>
    <td>
      <em>
        If the viewing user is logged in as the requester themselves (or an
        <a href="{{page.baseurl}}/docs/glossary/#admin" class="glossary__link">administrator</a>):
      </em>
      <br>
      the item is displayed, together with a notice indicating that it is
      hidden to all but the requester, followed by a specific reason for it
      having been hidden if the administrator has provided one.
      <br>
      <em>
        otherwise:
      </em>
      <br>
      The item is not displayed, and an explanation is shown (same as
      <em>hidden</em>, above).
    </td>
  </tr>
</table>

<span>*</span> the actual message may be different, depending on your
<a href="{{page.baseurl}}/docs/glossary/#theme" class="glossary__link">theme</a>
or translation.

## Hiding requests and responses

The general process for hiding messages that Alaveteli has sent or received is
to find it in the admin interface, go to edit it, and change the prominence.
For more detail, see:

* how to [hide a request (that is, the whole page)]({{ page.baseurl }}/docs/running/requests/#hiding-a-request)
* how to [hide an incoming or outgoing message]({{ page.baseurl }}/docs/running/admin_manual/#hiding-an-incoming-or-outgoing-message)

The most common reason for hiding a message is if it contains personal,
sensitive, or libellous content.

If the body of the message contains other information which is relevant
and can be published, you should edit the message instead of hiding it.

If a request is obviously vexatious, and especially if it has been created
by a user who repeatedly makes such requests, you should hide it. People
who are making their first Freedom of Information requests using your 
site may be influenced by the precedent of requests that have already been
published. Hiding inappropriate requests may encourage good ones.


## Editing or hiding  annotations (comments)

Annotations are comments added by users to a request page. As an administrator,
you can edit, hide or unhide them. The admin interface makes it easy for you to
select and hide multiple comments on a single request page (rather than doing
it individually).

For instructions, see:

* how to [edit or hide annotations]({{ page.baseurl }}/docs/running/admin_manual/#editing-or-hiding-annotations-comments)

## Editing a message

As an administrator, you can change the text that is displayed in incoming or
outgoing messages.

<div class="attention-box info">
  Remember that normally this means you're changing a message <em>after</em> it
  has been sent &mdash; you won't be changing what was delivered, only what is
  displayed on your site.
</div>

For instructions, see:

* how to [edit the text of a message]({{ page.baseurl }}/docs/running/admin_manual/#editing-an-outgoing-message)

Obviously you should only do this to remove information that should not be
displayed. Examples of why you might need to do this:

* the message sender mistakenly included personal information in the request body, not realising it would be displayed publicly

* the body's response includes personal information wrongly included
  in the original request, which has been quoted

* part of the message contains obscene or libellous text &mdash; this can
  sometimes happen because, although the request is valid, the requester
  is angry or upset about the circumstances that have led to it being
  made

When you edit text, we recommend you clearly replace any text you remove with
an indication in place, such as "`[personal information removed]`" or 
"`[telephone number redacted]`".

## Erasing a message

Erasing a message (whether incoming or outgoing) replaces its body, subject and
sender/recipient name and address with nothing. There is still a trace that a
message was sent or received, but no content. When erasing a message, the admin
leaves a reason which is shown in place of the erased message.

## Deleting

In general, you should only delete material (that is, destroy it) if you're
sure it has no content that you, as administrator, will need to access, and
if nothing else depends on it now or later. For example, you should delete obvious
spam messages, but perhaps not an outgoing request that might elicit a genuine
response from the target body (even if you know it's not a valid Freedom of
Information request).

<div class="attention-box info">
  Remember that under normal circumstances Alaveteli will have sent the request
  before you delete it. Deleting it after it has been sent removes it from the
  site, and means any responses that are sent back to this request will instead
  end up in the
  <a href="{{ page.baseurl }}/docs/glossary/#holding_pen" class="glossary__link">holding pen</a>.
  This is why it is generally better to
  <a href="{{ page.baseurl }}/docs/running/requests/#hiding-a-request">hide the request</a>
  instead.
</div>

For instructions, see:

* how to [delete a request]({{ page.baseurl }}/docs/running/requests/#deleting-a-request)

If you delete a request, that operation cannot be undone. Likewise, deleting a
message or an attachment cannot by undone. A warning will be shown in the admin
interface when you are about to delete/destroy some material.

Once a record is destroyed, there is no trace of it on the site, so it is best to
avoid this whenever possible, as it goes against the objectives of transparency
for the site.

Note that destroying an item does not remove it from backups. It only removes data
from the database and `ActiveStorage` files. If it is critical to get rid of all
traces of some material, you may need to replace your backups. How to do this
is out of scope for this document.


## Redacting

Redacting information is more complicated than the other methods, because it
is automatic. There are several considerations here:

* because it is automatic, you must be careful that you do not redact information
  that does not need to be hidden &mdash; this may be very difficult to ensure

* the mechanism for redaction is powerful, so be careful not to make mistakes
  in complex cases

* redaction can be computationally expensive, so don't overuse it

* automatic redaction of material, especially in attachments (such as PDFs or
  image files) can never be 100% effective

Redaction is controlled by 
<a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">censor rules</a>
that describe the patterns in text that Alaveteli should remove, and the text
it should use as a replacement (for example, "`[passport number redacted]`").
The rules are applied to messages before their contents are published on your site.
Redaction attempts to remove text from attachments to messages, as well as the
message text itself.

Censor rules can easily be set to apply to an individual request, or all
requests for a given user. It's possible, with some coding, to apply redaction
to other scopes too.

There is another, less flexible, mechanism: text masks. These are applied to all
content on the site. By default, Alaveteli replaces phone numbers and email
addresses with text like `[hidden]`. As of Alaveteli version 0.47.x, the default
text masks can be customised for each site.

For details, see:

* how to [automatically redact information from incoming messages]({{ page.baseurl}}/docs/running/redaction/),
  which includes both general instructions and a detailed example.


## Attachment-specific options

Email attachments are part of an incoming message, so modifications that apply
to the message usually also apply to its attachments (redactions, erasures).

There are some additional concepts specific to attachments:

* **Locking** happens when some modification requires removing the original
  email file. In that case, Alaveteli saves a copy of the attachment that
  cannot be modified anymore (for instance, no new censor rules can be applied).

* **Replacing** an attachment consists in uploading a new version of an attachment
  to the site, which takes precedence over the original version. Replacing an
  attachment also locks it. This is typically used to remove PII from a scanned 
  PDF where CensorRules cannot do their job.

# User specific options

## Closing an account

When closing an account, it can no longer be accessed by its former owner.
Alerts no longer sent, and the public display of the account is very reduced.
All account data remains intact.

### Anonymising an account

The user's PII (name) is redacted for public display but we still hold the original data.
