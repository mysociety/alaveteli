---
layout: page
title: Alaveteli Professional
---

# Alaveteli Professional

<p class="lead">
    <strong>A toolset for professional users of FOI</strong><br>
    Everything journalists, researchers and campaigners need to conduct
    investigations.
</p>

## Configuration settings

The following are all the configuration settings that you can change in
`config/general.yml`. When you edit this file, remember it must be in the <a
href="http://yaml.org">YAML syntax</a>. It's not complicated but &mdash;
especially if you're editing a list &mdash; be careful to get the indentation
correct. If in doubt, look at the examples already in the file, and don't use
tabs.

<code><a href="#enable_alaveteli_pro">ENABLE_ALAVETELI_PRO</a></code>
<br> <code><a href="#pro_site_name">PRO_SITE_NAME</a></code>
<br> <code><a href="#pro_contact_name">PRO_CONTACT_NAME</a></code>
<br> <code><a href="#pro_contact_email">PRO_CONTACT_EMAIL</a></code>
<br> <code><a href="#pro_batch_authority_limit">PRO_BATCH_AUTHORITY_LIMIT</a></code>
<br> <code><a href="#forward_pro_nonbounce_responsed_to">FORWARD_PRO_NONBOUNCE_RESPONSES_TO</a></code>

## Translations

Alaveteli Pro’s translations must be translated through
[Transifex]({{ page.baseurl }}/docs/customising/translation/). The Pro-specific
translations are presented as an
[independent resource](https://www.transifex.com/mysociety/alaveteli/alaveteli-pro/)
to translate.

Enabling Alaveteli Pro also enables [a new help page](https://git.io/JJodZ) that
you’ll need to translate in the
[usual way]({{ page.baseurl }}/docs/customising/translation/).

---

## All the Alaveteli Professional settings

<dl class="glossary">
  <dt>
    <a name="enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a>
  </dt>
  <dd>
    <p>Enable Alaveteli Professional.</p>

    <p>If <code>ENABLE_ALAVETELI_PRO</code> is set to true, Alaveteli will
    include extra functionality and account levels for professional FOI users,
    e.g.  journalists. Professional users have access to a new dashboard, a more
    streamlined request process, and crucially, the ability to embargo their
    requests so that they remain private.</p>

    <p>Enabling this is a large change, and this is still in Alpha development,
    so you may want to contact the Alaveteli team before doing so.</p>

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>ENABLE_ALAVETELI_PRO: true</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_site_name"><code>PRO_SITE_NAME</code></a>
  </dt>
  <dd>
    <p>Site name for Alaveteli Professional.</p>

    <p>The name to use when referring to the Alaveteli Professional parts of an
    Alaveteli site. For example, in the UK our Alaveteli instance is called
    "WhatDoTheyKnow" but we refer to the pro parts of the site as
    "WhatDoTheyKnow Pro".</p>

    <p>If you don't want a different name for the pro pages, make this the same
    as SITE_NAME.</p>

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>PRO_SITE_NAME: 'Alaveteli Professional'</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_contact_name"><code>PRO_CONTACT_NAME</code></a> &amp;
    <a name="pro_contact_email"><code>PRO_CONTACT_EMAIL</code></a>
  </dt>
  <dd>
    <p>Contact name and email for Alaveteli Professional.</p>

    <p>If you want all support mail to go to the same address, make these the
    same as CONTACT_NAME & CONTACT_EMAIL.</p>

    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li><code>PRO_CONTACT_NAME: 'Alaveteli Professional Team'</code></li>
        <li><code>PRO_CONTACT_EMAIL: 'pro-team@example.com'</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_batch_authority_limit"><code>PRO_BATCH_AUTHORITY_LIMIT</code></a>
  </dt>
  <dd>
    The total number of authorities that can be added to a Alaveteli
    Professional batch request.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>PRO_BATCH_AUTHORITY_LIMIT: 500</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="forward_pro_nonbounce_responsed_to"><code>FORWARD_PRO_NONBOUNCE_RESPONSES_TO</code></a>
  </dt>
  <dd>
    The email address to which non-bounce responses to emails sent out to
    Alaveteli Professional users by Alaveteli should be forwarded.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>FORWARD_PRO_NONBOUNCE_RESPONSES_TO: pro-support@example.com</code></li>
      </ul>
    </div>
  </dd>
</dl>
