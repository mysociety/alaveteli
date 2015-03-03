---
layout: page
title: The holding pen
---

#  The holding pen

<p class="lead">
  
  The <em>holding pen</em> is where Alaveteli puts any incoming
  <a href="{{ site.baseurl }}docs/glossary/#response" class="glossary__link">responses</a>
  that can't be matched to a
  <a href="{{ site.baseurl }}docs/glossary/#request" class="glossary__link">request</a>
  automatically.
</p>


Alaveteli works by emailing requests to the correct target
<a href="{{ site.baseurl }}docs/glossary/#authority" class="glossary__link">authority</a>.
That email message is sent from a unique email address &mdash; that is, an
email address that is associated with that single request (technically,
Alaveteli hashes the request ID to generate a unique address and uses this as
the `Reply-to:` address).

So whenever an authority replies (by email) to a request that Alaveteli has
sent, that response will be addressed to that request's unique email address.
The email is received by your installation's
<a href="{{ site.baseurl}}docs/glossary/#mta" class="glossary__link">MTA</a>,
and is passed on to Alaveteli. In this way, incoming messages are easily
matched with the request they are responses to &mdash; this is important
because your site displays the responses underneath their original request, on
the request's page.

Normally, this works fine. But sometimes things go wrong, and a message comes
in that can't be matched with a request. When this happens, Alaveteli puts the
message in the
<a href="{{ site.baseurl }}docs/glossary/#holding_pen" class="glossary__link">holding
pen </a>.

Messages wait in the holding pen until an 
<a href="{{ site.baseurl }}docs/glossary/#super" class="glossary__link">administrator</a>
redelivers them to the correct request, or else deletes them.

## Why messages end up in the holding pen

There are several reasons why a message might end up in the holding pen:

* **the authority "broke" the reply-to email**<br>
  This can happen if the authority replies "by hand" to the incoming email &mdash;
  for example if the person at the authority accidentally loses the first
  letter of the email address when they copy-and-paste it. Or if they copy
  it manually and simply get it wrong.

* **there's something unusual about the way it was sent**<br>
  For example, if it was delivered here because the address is in the `Bcc:`
  field, and is not the `To:` address.

* **a partial email address may have been guessed**<br>
  This may be because someone has guessed an email address either because they
  have misunderstood how the addresses are formed, or due to a deliberate 
  attempt to send spam.

* **the response has been rejected and rejections are set to go to the holding pen**<br>
  Incoming mail that is correctly addressed but not accepted for the request
  goes into the holding pen if the request's `handle_rejected_responses`
  behaviour is set to `holding_pen` (rather than bouncing the email back to
  the sender, or simply deleting it). Responses may be rejected for various
  reasons &mdash; for example, if a response is sent from an unrecognised 
  email address for a request whose *Allow new responses from* setting is
  `authority_only`.
  
## What to do: redeliver or delete

You need to be an
<a href="{{ site.baseurl }}docs/glossary/#super" class="glossary__link">administrator</a>
to modify the holding pen.

There are two things you can do to a message in the holding pen:

  * **find the right request, and redeliver the message**<br>
    Alaveteli tries to guess the right request to help you, so sometimes
    you can just accept its suggestion. 
    
  * **delete the message**<br>
    If the message is not a response, you can delete it.

For instructions, see
[removing a message from the holding pen]({{ site.baseurl }}docs/running/admin_manual/#removing-a-message-from-the-holding-pen).

If the `To:` address does not belong to a valid request and the message is
clearly spam you can add that email address to Alaveteli's
<a href="{{site.baseurl}}#spam-address-list" class="glossary__link">spam address list</a>.
Subsequent messages to that address will be automatically rejected &mdash; for
instructions see
[rejecting spam that arrives in the holding pen]({{ site.baseurl }}docs/running/admin_manual/#rejecting-spam-that-arrives-in-the-holding-pen).

