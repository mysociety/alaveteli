---
layout: page
title: Managing requests
---

# Managing Requests


<p class="lead">
  Alaveteli makes it easy for a user to make a
  <a href="{{ site.baseurl }}docs/glossary/#request" class="glossary__link">request</a>.
  As an 
  <a href="{{ site.baseurl }}docs/glossary/#super" class="glossary__link">administrator</a>,
  there are some things about that request you can change once it&rsquo;s been created.
</p>

A request is automatically created when a user submits and (where necessary)
confirms it. Alaveteli sends it to the
<a href="{{ site.baseurl }}docs/glossary/#authority" class="glossary__link">authority</a>
responsible and handles any
<a href="{{ site.baseurl }}docs/glossary/#response" class="glossary__link">responses</a>.
Usually this process runs without needing any intervention from an
administrator. But sometimes you'll want to change some aspect of the request,
or the way Alaveteli is handling it.

<ul class="toc">
  <li><a href="#what-state-is-the-request-in">What state is the request in?</a></li>
  <li><a href="#changing-things-about-a-request">Changing things about a request</a></li>
<li><a href="#resending-a-request-or-sending-it-to-a-different-authority">Resending a request or sending a request to a different authority</a></li>
  <li><a href="#hiding-a-request">Hiding a request</a></li>
  <li><a href="#deleting-a-request">Deleting a request</a></li>
</ul>

## What state is the request in?

Every request moves through a series of 
<a href="{{ site.baseurl }}docs/glossary/#state" class="glossary__link">states</a>,
indicating its progress. Usually a new request will be in the
`waiting_response` state until something happens to change that &mdash; for
example, a response is received.

However, states can't always be set automatically, because they require a
decision to be made on what kind of answer the authority provided in the
response. For states like this, Alaveteli invites the original requester to
describe it &mdash; for example, when a response is received they can change
the state to `successful`, `partially_successful` or `not_held` (if the
authority replied to say they don't have the information requested).

<div class="attention-box info">
  If a request has been waiting for over three weeks for the original
  requester to describe it but has still not been described, Alaveteli
  lets <em>anyone</em> classify it.
</div>

Internally, Alaveteli does not just record the "described state" of a request,
but also notices if anything has happened since it was last described and
sets its "awaiting description" status appropriately.


## Changing things about a request

To change any of these settings, go to the 
<a href="{{ site.baseurl }}docs/glossary/#admin" class="glossary__link">admin interface</a>,
click on **Requests**, then click on the title of the request you want to affect. 
Click the **Edit metadata** button.

<table class="table">
  <tr>
    <th>
      What you can change
    </th>
    <th>
      Details
    </th>
  </tr>
  <tr>
    <td>
      Title
    </td>
    <td>
      The <em>title</em> is shown on the request&rsquo;s page, but is also used
      in the URL (the text is changed to lower case, punctuation is removed
      and, if necessary, a number is added for disambiguation &mdash; this is
      called the &ldquo;slug&rdquo;).
      <p>
        Note that changing the title changes the URL, because the slug changes
        &mdash; this means any links to the <em>old</em> URL will no longer
        work, and will return a 404 (file not found) error.
      </p>
    </td>
  </tr>
  <tr>
    <td>
      Who&nbsp;can&nbsp;see&nbsp;it?
    </td>
    <td>
      Change the <strong>Prominence</strong> setting to one of:
      <ul>
        <li><code>normal</code></li>
        <li>
          <code>backpage</code>: request can be seen by anyone (by visiting
          its URL, for example) but does not appear in lists, or search results
        </li>
        <li>
          <code>requester_only</code>: request only visible to the person who
          made the request
        </li>
        <li>
          <code>hidden</code>: request is never shown (except to administrators)
        </li>
      </ul>
      <br>
    </td>
  </tr>
  <tr>
    <td>
      Who can respond?
    </td>
    <td>
      The <strong>Allow new responses from...</strong> setting can be one of:
      <ul>
        <li><code>anybody</code></li>
        <li>
          <code>authority_only</code>: responses are allowed if they come
          from the authority to which the request was sent, or from any domain
          from which a a response has <em>already</em> been accepted
        </li>
        <li>
          <code>nobody</code>: no responses are allowed on this request
        </li>
      </ul>
      Any response from a sender who has been disallowed by this
      setting will be rejected (see next entry).
    </td>
  </tr>
  <tr>
    <td>
      What happens to rejected responses?
    </td>
    <td>
      The <strong>Handle rejected responses...</strong> setting specificies
      what happens to responses that are not allowed (see previous entry):
      <ul>
        <li>
          <code>bounce</code>: responses are sent back to their sender
        </li>
        <li>
          <code>holding pen</code>: responses are put in the
          <a href="{{ site.baseurl }}docs/glossary/#holding_pen" class="glossary__link">holding pen</a>
          for an administrator to deal with
        </li>
        <li>
          <code>blackhole</code>: responses are destroyed by being sent to a
          <a href="{{ site.baseurl }}docs/glossary/#blackhole" class="glossary__link">black hole</a>
        </li>
      </ul>
    </td>
  </tr>
  <tr>
    <td>
      What state is it in?
    </td>
    <td>
      See <a href="{{ site.baseurl }}docs/customising/states/">more about
      request states</a>, which can be customised for your installation.
      <p>
        You can force the state of the request by choosing it explicitly.
        Change the <strong>Described state</strong> setting.
      </p>
      <p>
        You may also need to set <strong>Awaiting description</strong> if,
        having changed the state, you want the original requester to update the
        description. For example, if the state depends on the information
        within the response, and you want the requester to classify it &mdash;
        see
        <em><a href="#what-state-is-the-request-in">What state is the request in?</a></em>
        above.
      </p>
    </td>
  </tr>
  <tr>
    <td>
      Are comments allowed?
    </td>
    <td>
      The <strong>Are comments allowed?</strong> setting simply you choose to 
      allow or forbid annotations and comments on this request.
      <p>
        Note that this won&rsquo;t hide any annotations that have already
        been left on the reques &mdash; it only prevents users adding new ones.
      </p>
    </td>
  </tr>
  <tr>
    <td>
      Tags (search&nbsp;keywords)
    </td>
    <td>
      Enter tags, separated by spaces, that are associated with this request.
      A tag can be either a simple keyword, or a key-value pair (use a colon as
      the separator, like this: <code>key:value</code>).
      <p>
        Tags are used for searching. Users and administators both benefit if
        you tag requests with useful keywords, because it helps them find
        specific requests &mdash; especially if your site gets busy and there
        are very many in the database.
      </p>
      <p>
        Although it&rsquo;s a little more complex than tags on requests,
        <a href="{{ site.baseurl }}docs/glossary/#category" class="glossary__link">categories</a>
        also use tags:
        see 
        <a href="{{ site.baseurl }}docs/running/categories_and_tags/">more about tags</a>
        for a little more information.
      </p>
    </td>
  </tr>
</table>

## Resending a request or sending it to a different authority

If you have corrected the email address for an authority, you can resend
an existing request to that authority to the new email address. Alternatively,
a user may send a request to the wrong authority. In that situation, you can
change the authority on the request and then resend it to the correct authority.

To resend a request, go to
the <a href="{{ site.baseurl }}docs/glossary/#admin"
class="glossary__link">admin interface</a>, click on **Requests**, then
click on the name of the request you want to change. Go to the **Outgoing messages** heading. Click the chevron next to the first outgoing message, which is the initial request. A panel of information about that message will appear. Click on the **Resend** button.

To send a request to a different authority, go to
the <a href="{{ site.baseurl }}docs/glossary/#admin"
class="glossary__link">admin interface</a>, click on **Requests**, then
click on the name of the request you want to change. In the **Request
metadata** section, there is a line which shows the authority. Click the
**move...** button next to it. Enter the **url_name** of the authority
that you want to send the request to.

<div class="attention-box info">
Users, requests and authorities all have <strong>url_names</strong>. This can be found in the metadata section of their admin page. The url_name makes up the last part of the URL for their public page. So, for a request with the url_name &ldquo;example_request&rdquo;, the public page URL will be <code>/request/example_request</code>.
</div>

Now click the **Move request to
authority** button. You will see a notice at the top of the page telling
you that the request has been moved. You can now resend the request as above.


## Hiding a request

You can hide an entire request. Typically you do this if it's not a valid
Freedom of Information request (for example, a request for personal
information), or if it is vexatious.

Go to the <a href="{{ site.baseurl }}docs/glossary/#admin" class="glossary__link">admin interface</a>,
click on **Requests**, then click on the title of the request you want. You can
hide it in one of two ways:

   * [Hide the request and notify the requester](#hide-the-request-and-notify-the-requester)
   * [Hide the request without notifying the requester](#hide-the-request-without-notifying-the-requester)

Responses to a hidden request will be accepted in the normal way, but because
they are added to the request's page, they too will be hidden.

### Hide the request and notify the requester

Scroll down to the *Actions* section of the request's admin page.
Choose one of the options next to **Hide the request and notify the user:**

   * Not a valid FOI request
   * A vexatious request

Choosing one of these will reveal an email form. Customise the text of the
email that will be sent to the user, letting them know what you've done. When
you're ready, click the **Hide request** button.

### Hide the request without notifying the requester

<div class="attention-box helpful-hint">
  As well as hiding the request from everyone, you can also use this method if
  you want to make the request only visible to the requester.
</div>
  
In the *Request metadata* section of the request's admin page, click the
**Edit metadata** button. Change the *Prominence* value to one of these:

  * `requester_only`: only the requester can view the request
  * `hidden`: nobody can see the request, except administrators.

<div class="attention-box warning">
  If you want to hide the request, do not chooose  <code>backpage</code>
  as the prominence. The <code>backpage</code> option stops the request
  appearing in lists and searches so that it is effectively only visible
  to anyone who has its URL &mdash; but it <em>does not hide</em> the request.
</div>

When you're ready, click the **Save changes** button at the bottom of the
*Edit metadata* section. No email will be sent to the requester to notify
them of what you've done.


## Deleting a request

You can delete a request entirely. Typically, you only need to do this if
someone has posted private information.  If you delete a request, any responses that it has already received will be
destroyed as well.

<div class="attention-box warning">
  Deleting a request destroys it. There is no &ldquo;undo&rdquo; operation.
  If you're not sure you want to do this, perhaps you should
  <a href="#hiding-a-request">hide the request</a> instead.
</div>

Go to the <a href="{{ site.baseurl }}docs/glossary/#admin" class="glossary__link">admin interface</a>,
click on **Requests**, then click on the title of the request you want to delete. 
Click the **Edit metadata** button. Click on the red **Destroy request entirely**
button at the bottom of the page.

Responses to a deleted request will be sent to the
<a href="{{ site.baseurl }}docs/glossary/#holding_pen" class="glossary__link">holding pen</a>.


