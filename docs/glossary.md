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
  <li><a href="#alaveteli">Alaveteli</a></li>
  <li><a href="#agnostic">asker agnostic</a></li>
  <li><a href="#authority">authority</a></li>
  <li><a href="#blackhole">black hole</a></li>
  <li><a href="#bounce-message">bounce message</a></li>
  <li><a href="#capistrano">Capistrano</a></li>
  <li><a href="#censor-rule">censor rule</a></li>
  <li><a href="#development">development site</a></li>
  <li><a href="#foi">freedom of information</a></li>
  <li><a href="#git">git</a></li>
  <li><a href="#holding_pen">holding pen</a></li>
  <li><a href="#newrelic">New Relic</a></li>
  <li><a href="#mta">MTA</a></li>
  <li><a href="#po">.po files</a></li>
  <li><a href="#production">production site</a></li>
  <li><a href="#publish">publish</a></li>
  <li><a href="#recaptcha">recaptcha</a></li>
  <li><a href="#redact">redacting</a></li>
  <li><a href="#regexp">regular expression</a></li>
  <li><a href="#request">request</a></li>
  <li><a href="#release">release</a></li>
  <li><a href="#response">response</a></li>
  <li><a href="#rails">Ruby&nbsp;on&nbsp;Rails</a></li>
  <li><a href="#sass">Sass</a></li>
  <li><a href="#staging">staging site</a></li>
  <li><a href="#state">state</a></li>
  <li><a href="#theme">theme</a></li>
</ul>


<dl class="glossary">

  <dt>
    <a name="alaveteli">Alaveteli</a>
  </dt>
  <dd>
    <strong>Alaveteli</strong> is the name of the open source software platform created
    by <a href="https://www.mysociety.org">mySociety</a> for submitting,
    managing and archiving Freedom of Information requests.
    <p>
      It grew from the successful FOI UK project
      <a href="https://www.whatdotheyknow.com">WhatDoTheyKnow</a>.
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
          An administrator can add, edit, or remove authorities in the admin
        </li>
        <li>
          Authorities are usually, but not always, public bodies that are obliged by the local
          <a href="#foi" class="glossary__link">Freedom of Information</a> (FoI) law to respond. Sometimes an
          Alaveteli site is set up in a jurisdiction that does not yet have FoI law. In the UK,
          we add some authorites to our <a href="https://www.whatdotheyknow.com">WhaDoTheyKnow</a>
          site that are not subject to FoI law, but which have either voluntarily submitted themselves
          to it, or which we believe should be accountable in this way.
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
          <code><a href="{{site.baseurl}}docs/customising/config/#blackhole_prefix">BLACKHOLE_PREFIX</a></code>
          to specify what this email address looks like.
        </li>
        <li>
          Conversely, see
          <code><a href="{{site.baseurl}}docs/customising/config/#contact_email">CONTACT_EMAIL</a></code>
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
          <a href="{{ site.baseurl }}docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>
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
          how to <a href="{{ site.baseurl }}docs/installing/deploy/">deploy Alaveteli</a> (and why it's
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
          see the
          <a href="{{ site.baseurl }}docs/running/admin_manual/">admin manual</a>
          for more about censor rules
        </li>
        <li>
          censor rules may simply redact text that exactly matches a
          particular sentence or phrase, or may use
          <a href="#regexp">regular expressions</a>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="development">development site</a> (also: dev, development server)
  </dt>
  <dd>
    A <strong>dev server</strong> is one that is running your Alaveteli site
    so you can <a href="{{ site.baseurl }}docs/customising/">customise it</a>, experiment
    with different settings, and test that it does what you expect.
    This is different from a
    <a href="#production" class="glossary__link">production server</a>, which is the one your
    users actually visit running with live data, or a
    <a href="#staging" class="glossary__link">staging server</a>,
    which is used for testing code before it goes live.
    <p>
      On your dev server, you should set
      <code><a href="{{site.baseurl}}docs/customising/config/#staging_site">STAGING_SITE</a></code>
      to <code>1</code>.
    </p>
  </dd>

  <dt>
    <a name="foi">Freedom of Information</a> (also FOI)
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
    <a name="git">git</a> (also github,  git repository, and git repo)
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
          See the <a href="{{ site.baseurl }}docs/installing/">installation instructions</a> which will
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
    The <strong>holding pen</strong> is the conceptual place where responses that
    could not be delivered are held. They need attention from a administrator.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          see the <a href="{{ site.baseurl }}docs/running/admin_manual/">admin manual</a> for
          information on dealing with emails in the holding pen
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="mta">MTA</a> (Mail Transfer Agent)
  </dt>
  <dd>
    A <strong>Mail Tranfer Agent</strong> is the the program which actually sends
    and receives email. Alaveteli sends email on behalf of its users, and processes
    the <a href="#response" class="glossary__link">responses</a> and replies it receives.
    All this email goes through the MTA, which is a seperate service on your system.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          see these instructions for <a href="{{ site.baseurl }}docs/installing/email/">configuring your MTA</a>
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
          See the <a href="{{ site.baseurl }}docs/installing/manual_install/">manual installation</a> instructions.
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
    These are the files needed by the gettext mechanism Alaveteli uses for
    localisation. A <code>.pot</code> file is effectively a list of all the
    strings in the application that need translating. Each <code>.po</code>
    file contains the mapping between those strings, used as keys, and their
    translations for one particular language. The key is called the
    <em>msgid</em>, and its corresponding translation is the <em>msgstr</em>.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          See <a href="{{ site.baseurl }}docs/customising/translation/">translating
          Alaveteli</a> for an overview from a translator's point of view.
        </li>
        <li>
          See <a href="{{ site.baseurl }}docs/developers/i18n/">Internationalising
          Alaveteli</a> for more technical details.
        </li>
        <li>
          Alaveteli is on the  <a href="https://www.transifex.net/projects/p/alaveteli/">Transifex</a>
          website, which lets translators work on Alaveteli in a browser, without needing
          to worry about this underlying structure.
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
      <code><a href="{{site.baseurl}}docs/customising/config/#staging_site">STAGING_SITE</a></code>
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
      <a href="{{ site.baseurl }}docs/installing/deploy/">deployment mechanism</a>
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
          <code><a href="{{site.baseurl}}docs/customising/config/#recaptcha_public_key">RECAPTCHA_PUBLIC_KEY</a></code>
          and
          <code><a href="{{site.baseurl}}docs/customising/config/#recaptcha_private_key">RECAPTCHA_PRIVATE_KEY</a></code>
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
          see the
          <a href="{{ site.baseurl }}docs/running/admin_manual/">admin manual</a>
          for more about how and when you may need to redact information
        </li>
        <li>
          you can do text-only redaction with Alaveteli's
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
          See <a href="http://localhost:4000/docs/customising/translation/">translating
          Alaveteli</a> for more information.
        </li>
        <li>
          We encourage you use the <a href="{{site.baseurl}}docs/installing/deploy/">deployment
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
    <a name="rails">Ruby on Rails</a> (also Rails)
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
          Alavateli's <a href="{{ site.baseurl }}docs/developers/directory_structure/">directory structure</a>
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
          more about <a href="{{ site.baseurl }}docs/customising/themes/#changing-the-colour-scheme">changing
          your colour scheme</a>, which uses Sass
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
      <code><a href="{{site.baseurl}}docs/customising/config/#staging_site">STAGING_SITE</a></code>
      to <code>1</code>.
    </p>
    <p>
      If you have a staging server, the system environment of your staging and
      production servers should be identical.
    </p>
    <p>
      You should never need to edit code directly on your production or staging servers.
      We strongly recommend you use Alaveteli's
      <a href="{{ site.baseurl }}docs/installing/deploy/">deployment mechanism</a>
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
          <a href="{{ site.baseurl }}docs/customising/states/">example states for WhatDoTheyKnow</a>
          (Alaveteli site running in the UK)
        </li>
        <li>
          for comparison, <a href="{{ site.baseurl }}docs/customising/states_informatazyrtare/">example states for InformataZyrtare</a>
          (Alaveteli site running in Kosovo)
        </li>
        <li>
          to customise or add your own states, see <a href="{{ site.baseurl }}docs/customising/themes/#customising-the-request-states">Customising the request states</a>
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
      <a href="{{ site.baseurl }}docs/customising/themes/">about themes</a>
        </li>
      </ul>
    </div>
  </dd>

</dl>
