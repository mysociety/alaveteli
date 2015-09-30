---
layout: page
title: Hiding or removing information
---

# Hiding or removing information

<p class="lead">
  Your Alaveteli site first and foremost publishes requests and responses,
  but there are circumstances when you will need to hide information too.
  This page summarises what you might need to do, and how Alaveteli
  supports it.
</p>

We know from our own experience running
<a href="{{ site.baseurl }}docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>
in the UK that it is sometimes necessary to remove information from the site.
Furthermore, sometimes this needs to be done sensitively, swiftly, and
transparently.

This page provides an overview of the ways you can hide or remove things from
your Alaveteli site, and some reasons why you might need to.

## Hiding, deleting, editing & redacting

There are four different approaches to removing information on your site:

* **Hiding** keeps the data, but does not display it. Administrators (and,
  optionally, the user who made a request that has been hidden) can still
  access hidden the content.

* **Deleting** removes the item completely. This makes sense for spam, but
  generally we recommend hiding rather than deleting content.

* **Editing** lets an administrator change text in messages.

* **Redacting** is the _automated_ removal of content based on pattern-matching
  (for example, removing all occurrences of a particular bank account number).


## How hiding works: prominence

Alaveteli displays things depending on their _prominence_. When you hide
requests or responses, you do so by changing their prominence, which you can do
in the
<a href="{{ site.baseurl }}docs/glossary/#admin" class="glossary__link">admin interface</a>.

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
      they have the URL (which external search engines may be linking to).
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
        <a href="{{site.baseurl}}docs/glossary/#super" class="glossary__link">administrator</a>):
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
<a href="{{site.baseurl}}docs/glossary/#theme" class="glossary__link">theme</a>
or translation.

## Hiding requests and responses

The general process for hiding messages that Alaveteli has sent or received is
to find it in the admin interface, go to edit it, and change the prominence.
For more detail, see:

* how to [hide a request (that is, the whole page)]({{ site.baseurl }}docs/running/requests/#hiding-a-request)
* how to [hide an incoming or outgoing message]({{ site.baseurl }}docs/running/admin_manual/#hiding-an-incoming-or-outgoing-message)

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

* how to [edit or hide annotations]({{ site.baseurl }}docs/running/requests/#editing-or-hiding-annotations-comments)

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
  <a href="{{ site.baseurl }}docs/glossary/#hoding_pen" class="glossary__link">holding pen</a>. 
  This is why it is generally better to
  <a href="{{ site.baseurl }}docs/running/requests/#hiding-a-request">hide the request</a>
  instead.
</div>

For instructions, see:

* how to [delete a request]({{ site.baseurl }}docs/running/requests/#deleting-a-request)

If you delete a request, that operation cannot be undone.

## Editing a message

As an administrator, you can change the text that is displayed in incoming or
outgoing messages.

<div class="attention-box info">
  Remember that normally this means you're changing a message <em>after</em> it
  has been sent &mdash; you won't be changing what was delivered, only what is
  displayed on your site.
</div>

For instructions, see:

* how to [edit the text of a message]({{ site.baseurl }}docs/running/admin_manual/#editing-an-outgoing-message)

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
an indication in place, such as "`[REDACTED]`".


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
<a href="{{ site.baseurl }}docs/glossary/#censor-rule" class="glossary__link">censor rules</a>
that describe the patterns in text that Alaveteli should remove, and the text
it should use as a replacement (typically, this is "`[REDACTED]`"). The rules
are applied to messages before their contents are published on your site.
Redaction attempts to remove text from attachments to messages, as well as the
message text itself.

Censor rules can easily be set to apply to an individual request, or all
requests for a given user. It's possible, with some coding, to apply redaction
to other scopes too.

For details, see:

* how to [automatically redact information from incoming messages]({{ site.baseurl}}docs/running/redaction/),
  which includes both general instructions and a detailed example.


