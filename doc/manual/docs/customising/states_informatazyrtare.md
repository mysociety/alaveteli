---
layout: page
title: States of requests (InformataZyrtare)
---

# Request states: example comparison

<p class="lead">
  This page shows differences between states used on two different
  Alaveteli instances &mdash; one in Kosovo and one in the UK. This
  is a practical example showing that you can customise the states that
  your site uses.
</p>

The request states are defined in the Alaveteli code, and we recommend you use
them (provided they match the <a href="{{ page.baseurl }}/docs/glossary/#foi"
class="glossary__link">FOI law</a> in your own jurisdiction).

## InformataZyrtare.org (Kosovo) example

Requests made on Kosovo's Alaveteli instance,
[InformataZyrtare](http://informatazyrtare.org), use slightly different states
from those on the UK's instance, [WhatDoTheyKnow](http://www.whatdotheyknow.com)
(WDTK).

Generally, this arises simply because the local legislation, or the way the
groups running the sites work, are different in different places. Alavateli
facilitates this by allowing you to customise the states that are used.

This example is to show clearly that you can use different states depending on
your local requirements, and how that might look. See [Customising the request
states]({{ page.baseurl }}/docs/customising/themes/) for details on how to do this.

### States used by InformataZyrtare but not WDTK

   * <a href="#deadline_extended">deadline_extended</a>
   * <a href="#partial_rejected">partial_rejected</a>
   * <a href="#wrong_response">wrong_response</a>

### States used by WDTK but not InformataZyrtare

   * <a href="{{ page.baseurl }}/docs/customising/states/#awaiting_description">awaiting_description</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#gone_postal">gone_postal</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#internal_review">internal_review</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#user_withdrawn">user_withdrawn</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#waiting_response_very_overdue">waiting_response_very_overdue</a>

For more details, see all the [states used by WhatDoTheyKnow]({{ page.baseurl }}/docs/customising/states/) for details.


---

&nbsp;

### Details of InformataZytare states

The states which aren't represented on [WDTK's states]({{ page.baseurl }}/docs/customising/states/) are described
in a little more detail here:

<ul class="definitions">
  <li><a href="#deadline_extended">deadline_extended</a></li>
  <li><a href="#partial_rejected">partial_rejected</a></li>
  <li><a href="#wrong_response">wrong_response</a></li>
</ul>

<dl class="glossary">
  <dt>
    <a name="deadline_extended">deadline_extended</a>
  </dt>
  <dd>
      The Authority has requested deadline extension.
  </dd>
  <dt>
    <a name="partial_rejected">partial_rejected</a>
  </dt>
  <dd>
      Only part of the request has being refused but the successful request
      to an information has not been attached.
  </dd>
  <dt>
    <a name="wrong_response">wrong_response</a>
  </dt>
  <dd>
    The authority has replied but the response does not correspond to the request.
  </dd>

</dl>

