---
layout: page
title: States of requests
---

# Request states

<p class="lead">
  A <a href="{{site.baseurl}}docs/glossary/#request" class="glossary__link">request</a>
  passes through different <strong>states</strong> as it is processed. These may
  vary from one jurisdiction to another.
</p>

The request states are defined in the Alaveteli code, and we recommend you use
them (provided they match the <a href="{{ site.baseurl }}docs/glossary/#foi"
class="glossary__link">FOI law</a> in your own jurisdiction). But if you do need to
customise them, you can &mdash; see
<a href="{{ site.baseurl }}docs/customising/themes/#customising-the-request-states">Customising the request states</a> for details.

## WhatDoTheyKnow example

Requests made on the UK's Alaveteli instance, [WhatDoTheyKnow](https://www.whatdotheyknow.com),
may be in any of the states described below.

Note that your site doesn't need to use the same states as WhatDoTheyKnow does. For example,
Kosovo's instance uses slightly different states: see
[this comparison of their differences]({{ site.baseurl }}docs/customising/states_informatazyrtare/).

### States

<ul class="definitions">
  <li><a href="#waiting_response">waiting_response</a></li>
  <li><a href="#waiting_classification">waiting_classification</a></li>
  <li><a href="#waiting_response_overdue">waiting_response_overdue</a></li>
  <li><a href="#waiting_response_very_overdue">waiting_response_very_overdue</a></li>
  <li><a href="#waiting_clarification">waiting_clarification</a></li>
  <li><a href="#gone_postal">gone_postal</a></li>
  <li><a href="#not_held">not_held</a></li>
  <li><a href="#rejected">rejected</a></li>
  <li><a href="#successful">successful</a></li>
  <li><a href="#partially_successful">partially_successful</a></li>
  <li><a href="#internal_review">internal_review</a></li>
  <li><a href="#error_message">error_message</a></li>
  <li><a href="#requires_admin">requires_admin</a></li>
  <li><a href="#user_withdrawn">user_withdrawn</a></li>
  <li><a href="#awaiting_description">awaiting_description</a></li>
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
    Waiting for a classification of a response
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
    <a name="waiting_response_very_overdue">waiting_response_very_overdue</a>
  </dt>
  <dd>
    Waiting for a reply for a very long time
    <ul>
      <li>Automatic, if today's date is after the request date + holidays + (60 days (for schools) or 40 days (everyone else))</li>
      <li>When a user updates / visits something in this state, suggest they might want to complain about it; show things they might want to do</li>
      <li>Alert user by email when this state happens</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_clarification">waiting_clarification</a>
  </dt>
  <dd>
    The public authority would like part of the request explained
    <ul>
      <li>Prompt user to write followup</li>
      <li>if a user sends an outgoing message on a request in this state, automatically transitions to {{waiting_response}}</li>
      <li>three days after this state change occurs, send reminder to user to action it (assuming user isn't banned)</li>
      <li>Can't transition here from internal_review</li>
    </ul>
  </dd>

  <dt>
    <a name="gone_postal">gone_postal</a>
  </dt>
  <dd>
    The public authority would like to / has responded by post
    <ul>
      <li>If selected, remind user that in most cases authority should respond by email, and encourage followup.</li>
      <li>Give most recent authority correspondence email address for user to request postal by private email.</li>
      <li>Encourage user to update thread with annotation at later date.</li>
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
      <li>Suggest they add annotations or make a donation</li>
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
    <a name="internal_review">internal_review</a>
  </dt>
  <dd>
    Waiting for the public authority to complete an internal review of their handling of the request
    <ul>
      <li>Tell user they should expect a response within 20 days</li>
      <li>When sends email to authority, adds &#8220;Internal review of&#8221; to Subject</li>
      <li>Can be transitioned from the followup form</li>
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
    A strange reponse, required attention by the WhatDoTheyKnow team
    <ul>
    <li>a user is confused and doesn't know what state to set, so an admin can intervene</li>
    <li>Redirect to form to ask for more information</li>
    <li>Mark as needs admin attention</li>
    </ul>
  </dd>

  <dt>
    <a name="user_withdrawn">user_withdrawn</a>
  </dt>
  <dd>
    The requester has abandoned this request for some reason.
    <ul>
      <li>Prompt user to write message to tell authority</li>
    </ul>
  </dd>

  <dt>
    <a name="awaiting_description">awaiting_description</a>
  </dt>
  <dd>
    This state, awaiting_description, is not really a state but a flag indicating that there is no state.
  </dd>

</dl>

