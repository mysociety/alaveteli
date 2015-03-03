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


