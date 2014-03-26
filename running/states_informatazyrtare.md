---
layout: page
title: Request states
---

# Request states

<p class="lead">
  A <a href="{{site.baseurl}}glossary/#request">request</a> passes through different <strong>states</strong> as it is processed. These may vary from one jurisdiction to another (you can configure them when you set your site up). <!-- TODO: specifiying states -->  
</p>


## InformataZyrtare.org (Kosovo) example

Requests made on Kosovo's Alaveteli instance, [InformataZyrtare](http://informatazyrtare.org), may be in any of the following states
(for comparison, the UK's instance uses 
[slightly different states]({{ site.baseurl }}running/states)):

### States

<ul class="definitions">
  <li><a href="#waiting_response">waiting_response</a></li>
  <li><a href="#waiting_classification">waiting_classification</a></li>
  <li><a href="#waiting_response_overdue">waiting_response_overdue</a></li>
  <li><a href="#waiting_clarification">waiting_clarification</a></li>
  <li><a href="#not_held">not_held</a></li>
  <li><a href="#rejected">rejected</a></li>
  <li><a href="#successful">successful</a></li>
  <li><a href="#partially_successful">partially_successful</a></li>
  <li><a href="#error_message">error_message</a></li>
  <li><a href="#requires_admin">requires_admin</a></li>
  <li><a href="#deadline_extended">deadline_extended</a></li>
  <li><a href="#partial_rejected">partial_rejected</a></li>
  <li><a href="#wrong_response">wrong_response</a></li>
</ul>


<dl class="glossary">

  <dt>
    <a name="waiting_response">waiting_response</a>
  </dt>
  <dd>
    Waiting for the public authority to reply
    <ul>
      <li>The default initial state</li>
      <li>Can't transition here from internal_review</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_classification">waiting_classification</a>
  </dt>
  <dd>
    <ul>
      <li>The default state after receiving a response</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_response_overdue">waiting_response_overdue</a>
  </dt>
  <dd>
    Waiting for a reply for too long    
    <ul>
      <li>Automatic, if today's date is after the request date + holidays + 20 days</li>
      <li>When a user updates / visits an item in this state, thank user and tell them how long they should have to wait</li>
      <li>Alert user by email when something becomes overdue</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_clarification">waiting_clarification</a>
  </dt>
  <dd>
    The public authority would like part of the request explained
    <ul>
      <li>Prompt user to write followup</li>
      <li>If a user sends an outgoing message on a request in this state, automatically transitions to {{waiting_response}}</li>
      <li>Three days after this state change occurs, send reminder to user to action it (assuming user isn't banned)</li>
      <li>Can't transition here from internal_review</li>
    </ul>
  </dd>

  <dt>
    <a name="not_held">not_held</a>
  </dt>
  <dd>
    The public authority does not have the information requested
    <ul>
      <li>Suggest user might want to try a different authority, or complain</li>
    </ul>
  </dd>

  <dt>
    <a name="rejected">rejected</a>
  </dt>
  <dd>
    The request was refused by the public authority
    <ul>
      <li>Show page of possible next steps</li>
    </ul>
  </dd>

  <dt>
    <a name="successful">successful</a>
  </dt>
  <dd>
    All of the information requested has been received
    <ul>
      <li>Suggest they add annotations or make a donation  </li>
    </ul>
  </dd>

  <dt>
    <a name="partially_successful">partially_successful</a>
  </dt>
  <dd>
    Some of the information requested has been received
    <ul>
      <li>Suggest they make a donation; give ideas what to do next</li>
    </ul>
  </dd>

  <dt>
    <a name="error_message">error_message</a>
  </dt>
  <dd>
    Received an error message, such as delivery failure.
    <ul>
      <li>Thank user for reporting, and suggest they use a form to give new email address for authority if that was the problem</li>
      <li>Mark as needs admin attention</li>
    </ul>
  </dd>

  <dt>
    <a name="requires_admin">requires_admin</a>
  </dt>
  <dd>
    A strange response, required attention by the InformataZyrtare team
    <ul>
      <li>A user is confused and doesn't know what state to set, so an admin can intervene </li>
      <li>Redirect to form to ask for more information </li>
      <li>Mark as needs admin attention</li>
    </ul>
  </dd>

  <dt>
    <a name="deadline_extended">deadline_extended</a>
  </dt>
  <dd>
    <ul>
      <li>If the Authority has requested deadline extension.</li>
    </ul>
  </dd>

  <dt>
    <a name="partial_rejected">partial_rejected</a> <em>TBD</em>
  </dt>
  <dd>
    Only part of the request has being refused but the successful request to an information has not been attached
    </ul>
  </dd>

  <dt>
    <a name="wrong_response">wrong_response</a>
  </dt>
  <dd>
    Authority has replied but the response does not correspond to the request
  </dd>
</dl>

<!-- 
  TODO: muckrock's states here?

# MuckRock.com

US FOI site MuckRock.com uses the following states:

**Draft**
Unfinished request

**Processing**
The MuckRock team are currently reviewing the request to decide what to do with it.

This is necessary because a lot of requests have to be mailed or faxed or have signatures, etc.  The system requires quite a lot of manual intervention.  Over time the plan is to automate more, but this state will still be required at a minimum to indicate that MuckRock is the holdup, not the requester or the agency.

**Awaiting Response**
Request sent, no reply received yet

**Fix Required**
If the authority or a MuckRock admin thinks that user needs to clarify or otherwise "fix" the request

**Payment Required**
In the US, an authority can ask a user to make a payment to cover the costs of the request

**Rejected**
Request rejected

**No responsive documents**
Information not held

**Completed**
Successfully finished request

**Partially Completed**
Finished request, partly successful

-->

