---
layout: page
title: Glossary
---

Glossary
====================

<p class="lead">
  Glossary of terms for Alaveteli, mySociety's freedom of information
  platform.
</p>

Definitions
-----------

<ul class="definitions">
  <li><a href="#admin">admin interface</a></li>
  <li><a href="#advanced-search">advanced search</a></li>
  <li><a href="#alaveteli">Alaveteli</a></li>
  <li><a href="#agnostic">asker agnostic</a></li>
  <li><a href="#authority">authority</a></li>
  <li><a href="#blackhole">black hole</a></li>
  <li><a href="#bounce-message">bounce message</a></li>
  <li><a href="#capistrano">Capistrano</a></li>
  <li><a href="#category">category</a></li>
  <li><a href="#categorisation-game">categorisation game</a></li>
  <li><a href="#censor-rule">censor rule</a></li>
  <li><a href="#development">development site</a></li>
  <li><a href="#disclosure-log">disclosure log</a></li>
  <li><a href="#emergency">emergency user</a></li>
  <li><a href="#foi">freedom of information</a></li>
  <li><a href="#geoip-database">GeoIP database</a></li>
  <li><a href="#gaze">gaze</a></li>
  <li><a href="#git">git</a></li>
  <li><a href="#holding_pen">holding pen</a></li>
  <li><a href="#holiday">holiday</a></li>
  <li><a href="#i18n">internationalisation</a></li>
  <li><a href="#newrelic">New Relic</a></li>
  <li><a href="#mta">Mail Transfer Agent</a></li>
  <li><a href="#po">.po files</a></li>
  <li><a href="#production">production site</a></li>
  <li><a href="#publish">publish</a></li>
  <li><a href="#publication-scheme">publication scheme</a></li>
  <li><a href="#recaptcha">recaptcha</a></li>
  <li><a href="#redact">redacting</a></li>
  <li><a href="#regexp">regular expression</a></li>
  <li><a href="#request">request</a></li>
  <li><a href="#release">release</a></li>
  <li><a href="#response">response</a></li>
  <li><a href="#rails">Ruby&nbsp;on&nbsp;Rails</a></li>
  <li><a href="#sass">Sass</a></li>
  <li><a href="#spam-address-list">spam address list</a></li>
  <li><a href="#staging">staging site</a></li>
  <li><a href="#state">state</a></li>
  <li><a href="#super">superuser</a></li>
  <li><a href="#tag">tag</a></li>
  <li><a href="#takedown">takedown request</a></li>
  <li><a href="#theme">theme</a></li>
  <li><a href="#transifex">Transifex</a></li>
  <li><a href="#wdtk">WhatDoTheyKnow</a></li>
</ul>


<dl class="glossary">

  <dt>
    <a name="admin">admin interface</a> (also: admin)
  </dt>
  <dd>
    The <strong>admin interface</strong> allows users who have
    <a href="{{ page.baseurl }}/docs/glossary/#super" class="glossary__link">super</a>
    administrator privilege to manage some aspects of how your
    Alaveteli site runs.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          You can access your installation's <a href="{{ page.baseurl }}/docs/glossary/#admin" class="glossary__link">admin interface</a>
          at <code>/admin</code>.
        </li>
        <li>
          To grant a user admin privilege, log into the admin and change
          their <em>Admin level</em> to "super" (or revoke the privilege
          by changing it to "none").
        </li>
        <li>
          On a newly-installed Alaveteli system, you can grant yourself
          <a href="{{ page.baseurl }}/docs/glossary/#emergency" class="glossary__link">emergency
          user</a>.
        </li>
        <li>
          For lots more about running an Alaveteli site, see the
          <a href="{{ page.baseurl }}/running/admin_manual">adminstrator's guide</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="advanced-search">advanced search</a>
  </dt>
  <dd>
    Alaveteli's <strong>advanced search</strong> lets users search using
    more complex criteria than just words. This includes Boolean operators,
    date ranges, and specific indexes such as <code>status:</code>,
    <code>requested_by:</code>, <code>status:</code> and so on.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          Advanced search is available on your Alaveteli site at
          <code>/advancedsearch</code>. That page shows suggestions and examples
          of the searches that are supported.
        </li>
        <li>
          For more about constructing complex queries, see
          <a href="http://xapian.org/docs/queryparser.html">Xapian
          search parser</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="alaveteli">Alaveteli</a>
  </dt>
  <dd>
    <strong>Alaveteli</strong> is the name of the open source software platform created
    by <a href="https://www.mysociety.org">mySociety</a> for submitting,
    managing and archiving Freedom of Information requests.
    <p>
      It grew from the successful FOI UK project
      <a href="#wdtk" class="glossary__link">WhatDoTheyKnow</a>.
      We use the name <em>Alaveteli</em> to distinguish the software
      that runs the platform from any specific website that it is powering.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          The Alaveteli website is at <a href="http://www.alaveteli.org">www.alaveteli.org</a>
        </li>
        <li>
          The name "Alaveteli" comes from
          <a href="http://en.wikipedia.org/wiki/Alaveteli,_Finland">Alaveteli in Finland</a>
          where
          <a href="http://en.wikipedia.org/wiki/Anders_Chydenius">an early FOI campaigner</a>
          once worked.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="agnostic">asker agnostic</a>
  </dt>
  <dd>
    <a href="#foi" class="glossary__link">Freedom of Information</a> (FoI) law typically considers
    the <a href="#response" class="glossary__link">responses</a> given by the
    <a href="#authority" class="glossary__link">authorities</a> to be <strong>asker agnostic</strong>. This means
    that the reply should not be any different depending on <em>who</em> asked for the
    information. One consequence of this is that the response
    can be <a href="#publish" class="glossary__link">published</a>, because in theory <em>everyone</em>
    could ask for it and expect, by law, to receive the same information.
    <p>
      Despite this, it's still very common all around the world for authorities to reply
      to FoI requests privately, instead of publishing their responses themselves. One of the
      functions of Alaveteli is, therefore, to act as a public repository of published answers.
      This also serves to reduce duplicate requests, by publishing the answer instead of
      requiring it to be asked again.
    </p>
  </dd>

  <dt>
    <a name="authority">authority</a>
  </dt>
  <dd>
    An <strong>authority</strong> is the term we use for any of the bodies, organisations,
    departments, or companies to which users can send <a href="#request" class="glossary__link">requests</a>.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          An <a href="#super" class="glossary__link">administrator</a>
          can add, edit, or remove authorities in the admin.
        </li>
        <li>
          Authorities are usually, but not always, public bodies that are obliged by the local
          <a href="#foi" class="glossary__link">Freedom of Information</a> (FoI) law to respond. Sometimes an
          Alaveteli site is set up in a jurisdiction that does not yet have FoI law. In the UK,
          we add some authorites to our <a href="https://www.whatdotheyknow.com">WhaDoTheyKnow</a>
          site that are not subject to FoI law, but which have either voluntarily submitted themselves
          to it, or which we believe should be accountable in this way.
        </li>
        <li>
          You can organise your authorities using
          <a href="{{ page.baseurl }}/docs/running/categories_and_tags/">categories and tags</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blackhole">black hole</a>
  </dt>
  <dd>
    A <strong>black hole</strong> is an email address that accepts and destroys
    any email messages that are sent to it. Alaveteli uses this for "do not
    reply" emails, which are usually automatically generated system emails.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          Use the config setting
          <code><a href="{{ page.baseurl }}/docs/customising/config/#blackhole_prefix">BLACKHOLE_PREFIX</a></code>
          to specify what this email address looks like.
        </li>
        <li>
          Conversely, see
          <code><a href="{{ page.baseurl }}/docs/customising/config/#contact_email">CONTACT_EMAIL</a></code>
          to specify the email address to which users' emails (such as support
          enquiries) will be delivered.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="bounce-message">bounce message</a>
  </dt>
  <dd>
    A <strong>bounce message</strong> is an automated electronic mail message from a mail system informing the sender of another message about a delivery problem.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>
        </li>
        <li>The wikipedia page on <a href="http://en.wikipedia.org/wiki/Bounce_message">bounce messages</a>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="capistrano">Capistrano</a>
  </dt>
  <dd>
    <strong>Capistrano</strong> is a remote server automation and deployment tool written in Ruby.
    Alaveteli's deployment mechanism, which is optional, uses it.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          how to <a href="{{ page.baseurl }}/docs/installing/deploy/">deploy Alaveteli</a> (and why it's
          a good idea)
        </li>
        <li>
         The <a href="http://capistranorb.com/">Capistrano website</a> has thorough documentation
         about the tool
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="category">category</a>
  </dt>
  <dd>
    You can arrange your <a href="#authority" class="glossary__link">authorities</a>
    into <strong>categories</strong> so that they are easier for your users
    to find. For example, you might put all different schools into the
    "School" category, and universities into "Universities". You can also
    group categories under headings (such as "Education").
   <p>
     These categories and headings appear on the list of public authorities that
     is displayed on your site.
   </p>
    <p>
      Use <a href="#tag" class="glossary__link">tags</a> to associate
      authorities with specific categories.
    </p>
        More about
    <a href="{{ page.baseurl }}/docs/running/categories_and_tags/">categories and tags</a>
</dd>
  <dt>
    <a name="categorisation-game">categorisation game</a>
  </dt>
  <dd>
   The categorisation game is a way that users of an Alaveteli site  can help the site stay current and accurate by updating the status of old requests where the original requester has never said whether the authority responded with the information or not.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          the categorisation game on the <a href="http://demo.alaveteli.org/categorise/play">demo Alaveteli site</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="censor-rule">censor rule</a>
  </dt>
  <dd>
    Alaveteli administrators can define <strong>censor rules</strong> to define
    which parts of replies or responses should be
    <a href="#redact" class="glossary__link">redacted</a>.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          <a href="{{ page.baseurl }}/docs/running/redaction/">more about redacting</a>
          using censor rules
        </li>
        <li>
          censor rules may simply redact text that exactly matches a
          particular sentence or phrase, or may use
          <a href="#regexp" class="glossary__link">regular expressions</a>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="development">development site</a> (also: dev, development server)
  </dt>
  <dd>
    A <strong>dev server</strong> is one that is running your Alaveteli site
    so you can <a href="{{ page.baseurl }}/docs/customising/">customise it</a>, experiment
    with different settings, and test that it does what you expect.
    This is different from a
    <a href="#production" class="glossary__link">production server</a>, which is the one your
    users actually visit running with live data, or a
    <a href="#staging" class="glossary__link">staging server</a>,
    which is used for testing code before it goes live.
    <p>
      On your dev server, you should set
      <code><a href="{{ page.baseurl }}/docs/customising/config/#staging_site">STAGING_SITE</a></code>
      to <code>1</code>.
    </p>
  </dd>

  <dt>
    <a name="disclosure-log">disclosure log</a>
  </dt>
  <dd>
    Some <a href="#authority" class="glossary__link">authorities</a> routinely
    publish their responses to <a href="#foi" class="glossary__link">Freedom of
    Information</a> requests online. This collection of responses is called a
    <strong>disclosure log</strong>, and if an authority has such a log on its
    website, you can add the URL so Alaveteli can link to it.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          You can add a disclosure log URL by
          <a href="{{ page.baseurl }}/docs/running/admin_manual/#creating-changing-and-uploading-public-authority-data">updating authority data</a> in the admin.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="emergency">emergency user</a>
  </dt>
  <dd>
    Alaveteli ships with a configuration setting for an <strong>emergency user</strong>.
    This provides a username and password you can use to access the admin, even though
    the user doesn't appear in the database.
    <p>
      When the system has been bootstrapped (that is, you've used the emergency user to
      grant a user account full <em>super</em> privileges), you must disable the emergency
      user.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          The username and password are defined by the configuration settings
          <code><a href="{{ page.baseurl }}/docs/customising/config/#admin_username">ADMIN_USERNAME</a></code>
          and
          <code><a href="{{ page.baseurl }}/docs/customising/config/#admin_password">ADMIN_PASSWORD</a></code>.
        </li>
        <li>
          For an example of using the emergency user, see
          <a href="{{ page.baseurl }}/docs/installing/next_steps/#create-a-superuser-account-for-yourself">creating
            a superuser account</a>.
        </li>
        <li>
          Disable the emergency user by setting
          <code><a href="{{ page.baseurl }}/docs/customising/config/#disable_emergency_user">DISABLE_EMERGENCY_USER:</a> true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="foi">Freedom of Information</a> (also: FOI)
  </dt>
  <dd>
    <strong>Freedom of information</strong> laws allow access by the general public
    to data held by national governments. They establish a "right-to-know"
    legal process by which requests may be made for government-held
    information, to be received freely or at minimal cost, barring standard
    exceptions.
    <br>
    <em>[from wikipedia]</em>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          Wikipedia summary of <a href="http://en.wikipedia.org/wiki/Freedom_of_information_laws_by_country">FOI laws by country</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="geoip-database">GeoIP database</a>
  </dt>
  <dd>
    <p>
      A GeoIP database is a local store of geographical information about IP addresses.
      By default, Alaveteli uses a GeoIP database to determine each user's country from
      their incoming IP address. This lets the site suggest an Alaveteli site in their
      country, if one exists.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>More about the free <a href="http://dev.maxmind.com/geoip/legacy/geolite/">GeoLite databases</a> from MaxMind.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="gaze">gaze</a>
  </dt>
  <dd>
    <p>
      In the absence of a <a href="#geoip-database">GeoIP database</a>, Alateveli uses
      mySociety's gazeteer service, called Gaze, to determine each user's country from
      their incoming IP address. This lets the site suggest an Alaveteli site in their
      country, if one exists.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>The config variable
          <code><a href="{{ page.baseurl }}/docs/customising/config/#gaze_url">GAZE_URL</a></code>
          should usually point at...
        </li>
        <li>...the <a
          href="http://gaze.mysociety.org/">Gaze service</a>.
        </li>
        <li>
          See <a href="https://github.com/mysociety/gaze">Gaze source on
          github</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="git">git</a> (also: github,  git repository, and git repo)
  </dt>
  <dd>
    We use a popular source code control system called <strong>git</strong>. This
    helps us track changes to the code, and also makes it easy for other people
    to duplicate and even contribute to our software.
    <p>
      The website <a href="https://github.com/mysociety">github.com</a> is a central, public
      place where we make our software available. Because it's Open Source, you can
      inspect the code there (Alaveteli is mostly written in the programming language
      Ruby), report bugs, suggest features and many other useful things.
    </p>
    <p>
      The entire set of files that form the Alaveteli platform is called the
      <strong>git repository</strong> or <strong>repo</strong>. When you
      install Alaveteli, you are effectively cloning our repository on your
      own machine.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          See the <a href="{{ page.baseurl }}/docs/installing/">installation instructions</a> which will
          clone the Alaveteli repo.
        </li>
        <li>
          Everything about git from the <a
          href="http://git-scm.com">official website</a>.
        </li>
        <li>
          See <a href="https://github.com/mysociety">the mySociety projects on
          github</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="holding_pen">holding pen</a>
  </dt>
  <dd>
    The <strong>holding pen</strong> is the conceptual place where responses
    that could not be delivered are held. They need attention from an
    <a href="#super" class="glossary__link">administrator</a>.
    <p>
      In fact, the holding pen is really a special "sticky" <a href="#request"
      class="glossary__link">request</a> that only exists to accept unmatched
      responses. Whenever Alaveteli receives an email but can't work out which
      request it is a response to, it attaches it to the holding pen instead.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          See more <a href="{{ page.baseurl }}/docs/running/holding_pen">about
          the holding pen</a>, including why messages end up there, and
          instructions on what to do with them.
        </li>
        <li>
          The most common reason for a response to be in the holding pen is that
          an <a href="#authority" class="glossary__link">authority</a> replied
          to a request with the wrong email address (for example, by copying
          the email address incorrectly).
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="holiday">holidays</a>
  </dt>
  <dd>
    Alaveteli needs to know about <strong>public holidays</strong> because
    they affect the calculation that determines when a
    <a href="#response" class="glossary__link">response</a> is overdue.
    Public holidays are different all around the world, so Alaveteli lets
    you specify the dates for the jurisdiction relevant to your
    site in the <a href="#admin" class="glossary__link">admin interface.</a> 
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          See more about
          <a href="{{ page.baseurl }}/docs/installing/next_steps/#add-some-public-holidays">adding
          public holidays</a>. It's possible to load dates from an iCalendar
          feed or accept Alaveteli's suggestions.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="i18n">internationalisation</a> (also: i18n)
  </dt>
  <dd>
    <strong>Internationalisation</strong> is the way Alaveteli adapts the
    way it presents text based on the language or languages that your website
    supports. It's sometimes abbreviated as <em>i18n</em> (because there are
    18 letters between i and n).
    <p>
      Often you don't need to worry about the details of how this is done
      because once you've configured your site's
      <code><a href="{{ page.baseurl }}/docs/customising/config/#default_locale">DEFAULT_LOCALE</a></code>
      Alaveteli takes care of it for you.
      But when you do need to work on i18n (for example, if you're customising
      your site by
      <a href="{{ page.baseurl }}/docs/customising/translation/">translating</a> it, or
      <a href="{{ page.baseurl }}/docs/running/admin_manual/#creating-changing-and-uploading-public-authority-data">uploading names</a>
      of the public bodies in more than one language) at the very least you may
      need to know the language codes your site is using.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          More about <a href="{{ page.baseurl }}/docs/developers/i18n/">internationalising Alaveteli</a>
        </li>
        <li>
          See mySociety's
          <a href="http://mysociety.github.io/internationalization.html">i18n guidelines</a> for developers
        </li>
        <li>
          <a href="http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes">List of language codes</a>
        </li>
        <li>
          For more about i18n in software generally, see
          the <a href="http://en.wikipedia.org/wiki/Internationalization_and_localization">i18n Wikipedia article</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="mta">Mail Transfer Agent</a> (MTA)
  </dt>
  <dd>
    A <strong>Mail Transfer Agent</strong> is the the program which actually sends
    and receives email. Alaveteli sends email on behalf of its users, and processes
    the <a href="#response" class="glossary__link">responses</a> and replies it receives.
    All this email goes through the MTA, which is a seperate service on your system.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          see these instructions for <a href="{{ page.baseurl }}/docs/installing/email/">configuring your MTA</a>
          (examples are for exim4 and postfix, two of the most common)
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="newrelic">New Relic</a>
  </dt>
  <dd>
    Alaveteli can use <strong>New Relic</strong>'s application monitoring tool to track the
    performance of your <a href="#production" class="glossary__link">production site</a>. If enabled,
    data from your application is gathered on the New Relic website, which you can inspect with
    their visual tools. Basic use is free.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          use the <code>agent_enabled:</code> setting in the
          the <code>newrelic.yml</code> config file to enable the New Relic analytics.
          See the <a href="{{ page.baseurl }}/docs/installing/manual_install/">manual installation</a> instructions.
        </li>
        <li>
          see also the New Relic Ruby Agent <a href="https://github.com/newrelic/rpm">github repo</a> and
          <a href="https://docs.newrelic.com/docs/ruby/">documentation</a>
        </li>
        <li>
          the <a href="http://newrelic.com">New Relic website</a>: if you've enabled the service,
          you can log in to inspect the perfomance analytics
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="po"><code>.po</code> file</a> (and <code>.pot</code> file)
  </dt>
  <dd>
    These are the files needed by the <code>gettext</code> mechanism Alaveteli
    uses for localisation. A <code>.pot</code> file is effectively a list of
    all the strings in the application that need translating. Each
    <code>.po</code> file contains the mapping between those strings, used as
    keys, and their translations for one particular language. The key is called
    the <em>msgid</em>, and its corresponding translation is the
    <em>msgstr</em>.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          See <a href="{{ page.baseurl }}/docs/customising/translation/">translating
          Alaveteli</a> for an overview from a translator's point of view.
        </li>
        <li>
          See <a href="{{ page.baseurl }}/docs/developers/i18n/">Internationalising
          Alaveteli</a> for more technical details.
        </li>
        <li>
          Alaveteli is on the  <a href="https://www.transifex.com/projects/p/alaveteli/">Transifex</a>
          website, which lets translators work on Alaveteli in a browser, without needing
          to worry about this underlying structure.
        </li>
        <li>
          See more about the
          <a href="https://www.gnu.org/software/gettext/"><code>gettext</code>
          system</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="production">production site</a> (also: live, production server)
  </dt>
  <dd>
    A <strong>production server</strong> is one that is running your Alaveteli site
    for real users, with live data. This is different from a
    <a href="#development" class="glossary__link">development server</a>, which you use make your
    customisation and environment changes and try to get them to all work OK, or a
    <a href="#staging" class="glossary__link">staging server</a>, which is used for testing code
    and configuration after it's been finished but before it goes live.
    <p>
      Your production site should be configured to run as efficiently as possible: for
      example, caching is enabled, and debugging switched off.
      <a href="#rails" class="glossary__link">Rails</a> has a "production mode" which does
      this for you: set
      <code><a href="{{ page.baseurl }}/docs/customising/config/#staging_site">STAGING_SITE</a></code>
      to <code>0</code>. Note that if you <em>change</em> this setting after you've
      deployed, the <code>rails_env.rb</code> file that enables Rails's production
      mode won't be created until you run <code>rails-post-deploy</code>.
    <p>
      If you have a staging server, the system environment of your staging and
      production servers should be identical.
    </p>
    <p>
      You should never need to edit code directly on your production server.
      We strongly recommend you use Alaveteli's
      <a href="{{ page.baseurl }}/docs/installing/deploy/">deployment mechanism</a>
      (using Capistrano) to make changes to your production site.
    </p>
  </dd>

  <dt>
    <a name="publish">publish</a>
  </dt>
  <dd>
    Alaveteli works by <strong>publishing</strong> the
    <a href="#response" class="glossary__link">responses</a> it recieves to the
    <a href="#foi" class="glossary__link">Freedom of Information</a>
    <a href="#request" class="glossary__link">requests</a> that its users send.
    It does this by processing the emails it receives and presenting them
    as pages &mdash; one per request &mdash; on the website. This makes it
    easy for people to find, read, link to, and share the request and the
    information provided in response.
  </dd>

  <dt>
    <a name="publication-scheme">publication scheme</a>
  </dt>
  <dd>
    Some <a href="#authority" class="glossary__link">authorities</a> have a
    <strong>publication scheme</strong> which makes it clear what information
    is readily available from them under <a href="#foi"
    class="glossary__link">Freedom of Information</a> law, and how people can
    get it. This may be a requirement for their compliance with the law, or it
    may simply be good practice. If an authority has published such a scheme on
    its website, you can add the URL so Alaveteli can link to it.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          You can add a publication scheme URL by
          <a href="{{ page.baseurl }}/docs/running/admin_manual/#creating-changing-and-uploading-public-authority-data">updating authority data</a> in the admin.
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="recaptcha">recaptcha</a>
  </dt>
  <dd>
    <strong>Recaptcha</strong> is a mechanism that deters non-human users,
    such as automated bots, from submitting requests automatically.
    It requires the (human) user to identify a pattern of letters presented
    in an image, which is difficult or impossible for a non-human to
    do. Alaveteli uses this to prevent incoming spam.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          use the config settings
          <code><a href="{{ page.baseurl }}/docs/customising/config/#recaptcha_public_key">RECAPTCHA_PUBLIC_KEY</a></code>
          and
          <code><a href="{{ page.baseurl }}/docs/customising/config/#recaptcha_private_key">RECAPTCHA_PRIVATE_KEY</a></code>
          to set this up.
        </li>
        <li>
          see the <a href="http://www.google.com/recaptcha/">recaptcha website</a> for more details
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="redact">redacting</a> (also: redaction)
  </dt>
  <dd>
    <strong>Redacting</strong> means removing or hiding part of a message so it
    cannot be read: you are effectively removing part of a document from
    your site.
    <p>
      This may be necessary for a variety of reasons. For example, a user may
      accidentally put personal information into their request, or an
      authority may include it in their response. You may also need to
      redact parts of requests or responses that are libellous or legally
      sensitive.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          redaction is just one way to hide sensitive information &mdash; see
          <a href="{{ page.baseurl }}/docs/running/hiding_information/">more about
          hiding information on Alaveteli</a>
        </li>
        <li>
          <a href="{{ page.baseurl }}/docs/running/redaction/">more about redacting</a>,
          including instructions for setting up
          <a href="#censor-rule" class="glossary__link">censor rules</a>
        </li>
        <li>
          some things are easier to redact than others &mdash; especially in PDFs,
          things like signatures or images can be difficult to partially remove.
          In such cases, you may need to remove the document entirely.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="regexp">regular expression</a> (also: regexp)
  </dt>
  <dd>
    A <strong>regular expression</strong> is a concise way to describe a
    pattern or sequence of characters, letters or words. As an administrator,
    you may find regular expressions useful if you need to define <a
    href="#censor-rule" class="glossary__link">censor rules</a>. For example, instead
    of <a href="#redact" class="glossary__link">redacting</a> just one specific
    phrase, you can describe a whole range of <em>similar</em> phrases with one
    single regular expression.
    <p>
      Regular expressions can be complicated, but also powerful. If you're not
      familiar with using them, it's easy to make mistakes. Be careful!
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          for example, the regular expression
          <code>Jo(e|ey|seph)\s+Blogg?s</code> would match names
          including
          "<code>Joe Bloggs</code>", "<code>Joey Bloggs</code>" and
          "<code>Joseph Blogs</code>", but not
          "<code>John Bloggs</code>".
        </li>
        <li>
          see <a href="http://en.wikibooks.org/wiki/Regular_Expressions"><em>Regular
          Expressions</em> on wikibooks</a> for more information
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="release">release</a> (also: release manager)
  </dt>
  <dd>
    We issue new <strong>releases</strong> of the Alaveteli code whenever key
    work (new features, improvements, bugfixes, and so on) have been added to
    the core code. Releases are identified by their tag, which comprises two or
    three numbers: major, minor, and &mdash; if necessary &mdash; a patch
    number. We recommend you always use the latest version. The process is
    handled by the Alaveteli <strong>release manager</strong>, who decides what
    changes are to be included in the current release, and the cut-off date for
    the work. Currently this is Alaveteli's lead developer at mySociety.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          The latest stable release is on the
          <a href="https://github.com/mysociety/alaveteli/tree/master">master branch</a>.
        </li>
        <li>
          See a <a href="https://github.com/mysociety/alaveteli/releases">list of all releases</a>
          and their explicit tags.
        </li>
        <li>
          We try to coordinate releases with any active translation work too.
          See <a href="{{ page.baseurl }}/docs/customising/translation/">translating
          Alaveteli</a> for more information.
        </li>
        <li>
          We encourage you use the <a href="{{ page.baseurl }}/docs/installing/deploy/">deployment
          mechanism</a>, which makes it easier to keep your production server up-to-date.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="request">request</a>
  </dt>
  <dd>
    In Alaveteli, a <strong>request</strong> is the
    <a href="#foi" class="glossary__link">Freedom of Information</a> request
    that a user enters, and which the site then emails to the relevant
    <a href="#authority" class="glossary__link">authority</a>.
    Alaveteli automatically <a href="#publish" class="glossary__link">publishes</a>
    the <a href="#response" class="glossary__link">responses</a>
    to all the requests it sends.
  </dd>

  <dt>
    <a name="response">response</a>
  </dt>
  <dd>
    A <strong>response</strong> is the email sent by an
     <a href="#authority" class="glossary__link">authority</a> in reply to
     a user's  <a href="#request" class="glossary__link">requests</a>.
  </dd>

  <dt>
    <a name="rails">Ruby on Rails</a> (also: Rails)
  </dt>
  <dd>
    Alaveteli is written in the Ruby programming language, using
    the web application framework "Ruby on Rails".
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          <a href="http://rubyonrails.org/">Ruby on Rails</a> website
        </li>
        <li>
          Alavateli's <a href="{{ page.baseurl }}/docs/developers/directory_structure/">directory structure</a>
          is influenced by its use of Ruby on Rails
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="sass">Sass</a> (for generating CSS)
  </dt>
  <dd>
    Alaveteli's cascading stylesheets (CSS) control how the pages appear, and
    are defined using <strong>Sass</strong>. It's technically a CSS extension
    language, and we use it because it's easier to manage than writing CSS
    directly (for example, Sass lets you easily make a single change that will
    be applied to many elements across the whole site).
    <a href="#rails" class="glossary__link">Rails</a> notices if you change any of
    the Sass files, and automatically re-generates the CSS files that the
    website uses.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          <a href="http://sass-lang.com">Sass website</a>
        </li>
        <li>
          more about <a href="{{ page.baseurl }}/docs/customising/themes/#changing-the-colour-scheme">changing
          your colour scheme</a>, which uses Sass
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="spam-address-list">spam address list</a>
  </dt>
  <dd>
    Alaveteli maintains a <strong>spam address list</strong>. Any incoming message to an email
    address on that list will be rejected and won't appear in the admin.
    <p>
      This is mainly for email addresses whose messages are ending up
      in the <a href="#holding_pen" class="glossary__link">holding pen</a>, because
      those are typically addresses that can be safely ignored as they do not
      relate to an active <a href="#request" class="glossary__link">request</a>.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          To add addresses to the spam address list , see
          <a href="{{ page.baseurl }}/docs/running/admin_manual/#rejecting-spam-that-arrives-in-the-holding-pen">Rejecting
          spam that arrives in the holding pen</a>.
        </li>
        <li>
          The spam address list is available on your site at <code>/admin/spam_addresses</code>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="staging">staging server</a> (also: staging site)
  </dt>
  <dd>
    A <strong>staging server</strong> is one that you use for testing code or configuration
    before it goes live. This is different from a <a href="#development"
    class="glossary__link">development server</a>, on which you change the code and settings to
    make everything work, or the
    <a href="#production" class="glossary__link">production server</a>, which is the
    site your users visit running with live data.
    <p>
      On your staging server, you should set
      <code><a href="{{ page.baseurl }}/docs/customising/config/#staging_site">STAGING_SITE</a></code>
      to <code>1</code>.
    </p>
    <p>
      If you have a staging server, the system environment of your staging and
      production servers should be identical.
    </p>
    <p>
      You should never need to edit code directly on your production or staging servers.
      We strongly recommend you use Alaveteli's
      <a href="{{ page.baseurl }}/docs/installing/deploy/">deployment mechanism</a>
      (using Capistrano) to make changes to these sites.
    </p>
  </dd>

  <dt>
    <a name="state">state</a>
  </dt>
  <dd>
    Each <a href="#request" class="glossary__link">request</a> passes through different
    <strong>states</strong> as it progresses through the system.
    States help Alaveteli administrators, as well as the public,
    understand the current situation with any request and what
    action, if any, is required.
    <p>
      The states available can be customised within
      your site's <a href="#theme" class="glossary__link">theme</a>.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          <a href="{{ page.baseurl }}/docs/customising/states/">example states for WhatDoTheyKnow</a>
          (Alaveteli site running in the UK)
        </li>
        <li>
          for comparison, <a href="{{ page.baseurl }}/docs/customising/states_informatazyrtare/">example states for InformataZyrtare</a>
          (Alaveteli site running in Kosovo)
        </li>
        <li>
          to customise or add your own states, see <a href="{{ page.baseurl }}/docs/customising/themes/#customising-the-request-states">Customising the request states</a>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="super">superuser</a> (also: super privilege, administrator)
  </dt>
  <dd>
    A <strong>superuser</strong>, or <strong>administrator</strong>, is an
    Alaveteli user who has been granted the privilege to use all features of the
    <a href="{{ page.baseurl }}/docs/glossary/#admin"
    class="glossary__link">admin interface</a>.
    <p>
      The only way to access the admin without being an Alaveteli superuser
      is as the <a href="{{ page.baseurl }}/docs/glossary/#emergency"
      class="glossary__link">emergency user</a>, which should be disabled in
      normal operation.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          To grant a user admin privilege, log into the admin and change
          their <em>Admin level</em> to "super" (or revoke the privilege
          by changing it to "none").
        </li>
        <li>
          On a newly-installed Alaveteli system, you can grant yourself
          admin privilege by using the
          <a href="{{ page.baseurl }}/docs/glossary/#emergency" class="glossary__link">emergency
          user</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="tag">tag</a>
  </dt>
  <dd>
    A <strong>tag</strong> is a keyword added to an
    <a href="#authority" class="glossary__link">authority</a>. Tags
    are searchable, so can be useful to help users find authorities based
    by topic or even unique data (for example, in the
    <a href="#wdtk" class="glossary__link">WhatDoTheyKnow</a> we tag every
    registered charity with its official charity number). You can also use
    tags to assign authorities to
    <a href="#category" class="glossary__link">categories</a>.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          More about
      <a href="{{ page.baseurl }}/docs/running/categories_and_tags/">categories and tags</a>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="takedown">takedown request</a>
  </dt>
  <dd>
    A <strong>takedown request</strong> is an appeal from someone asking or
    demanding that you remove information from your site. This may be because a
    response you have published contains illegal, personal, or sensitive
    information. Takedown requests may be made by people involved in the
    request or response, but can also be from third parties who are affected in
    some way by the information published.
    <p>
      Because Alaveteli automatically publishes messages, if a response or
      message contains inappropriate information, it will be published. So
      takedown requests often have merit, and part of the role of the admin
      team is to handle them quickly and fairly.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          More about
          <a href="{{ page.baseurl }}/docs/running/hiding_information/">hiding information</a>,
          including a process for handling for takedown requests
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme">theme</a>
  </dt>
  <dd>
    A <strong>theme</strong> is the collection of changes to the templates
    and the code that causes the site to look or behave differently from the
    default. Typically you'll need a theme to make Alaveteli show your own
    brand.
   <div class="more-info">
   <p>More information:</p>
     <ul>
       <li>
        <a href="{{ page.baseurl }}/docs/customising/themes/">about themes</a>
      </li>
    </ul>
   </div>
   </dd>
  <dt>

    <a name="transifex">Transifex</a>
  </dt>
  <dd>

    <a href="https://www.transifex.com/">Transifex</a> is a website that helps translators add translations for software projects.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          The Transifex project for Alaveteli is at <a href="https://www.transifex.com/projects/p/alaveteli">https://www.transifex.com/projects/p/alaveteli</a>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="wdtk">WhatDoTheyKnow</a>
  </dt>
  <dd>
    The website <strong>WhatDoTheyKnow</strong>.com is the UK installation of
    Alaveteli, run by <a href="http://mysociety.org">mySociety</a>.
    <p>
      In fact, WhatDoTheyKnow predates Alaveteli because the site started in
      2008, and was the foundation of the redeployable, customisable
      Alaveteli plattorm released in 2011.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          <a href="http://www.whatdotheyknow.com">WhatDoTheyKnow.com</a>
        </li>
      </ul>
    </div>
  </dd>

</dl>
