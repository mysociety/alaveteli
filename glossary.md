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
  <li><a href="#foi">freedom of information</a></li>
  <li><a href="#git">git</a></li>
  <li><a href="#holding_pen">holding pen</a></li>
  <li><a href="#mta">MTA</a></li>
  <li><a href="#publish">publish</a></li>
  <li><a href="#request">request</a></li>
  <li><a href="#response">response</a></li>
  <li><a href="#state">state</a></li>
  <li><a href="#theme">theme</a></li>
</ul>


<dl class="glossary">

  <dt>
    <a name="alaveteli">Alaveteli</a>
  </dt>
  <dd>
    <strong>Alaveteli</strong> is the name of the open source software platform created
    by <a href="http://www.mysociety.org">mySociety</a> for submitting,
    managing and archiving Freedom of Information requests.
    <p>
      It grew from the successful FOI UK project 
      <a href="http://www.whatdotheyknow.com">WhatDoTheyKnow</a>.
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
	  <a href="#foi" class="glossary">Freedom of Information</a> (FoI) law typically considers
    the <a href="#response" class="glossary">responses</a> given by the 
    <a href="#authority">authorities</a> to be <strong>asker agnostic</strong>. This means
    that the reply should not be any different depending on <em>who</em> asked for the 
    information. One consequence of this is that the response
    can be <a href="#publish" class="glossary">published</a>, because in theory <em>everyone</em>
    could ask for it and expect, by law, to receive the same information. 
    <p>
      Despite this, it's still very common all around the world for authorities to reply
      to FoI requests privately, instead of publishing their responses themselves. One of the
      functions of Alaveteli is, therefore, to act as a public repository of published answers.
      This also serves to reduce duplicate requests, by publishing the answer instead of
      requiring it to be asked again.
    </p>
  <dt>
    <a name="authority">authority</a>
  </dt>
  <dd>
	  An <strong>authority</strong> is the term we use for any of the bodies, organisations,
    departments, or companies to which users can send <a href="#request" class="glossary">requests</a>.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
          An administrator can add, edit, or remove authorities in the admin
        </li>
        <li>
          Authorities are usually, but not always, public bodies that are obliged by the local
          <a href="#foi" class="glossary">Freedom of Information</a> (FoI) law to respond. Sometimes an
          Alaveteli site is set up in a jurisdiction that does not yet have FoI law. In the UK,
          we add some authorites to our <a href="http://www.theyworkforyou.com">TheyWorkForYou</a>
          site that are not subject to FoI law, but which have either voluntarily submitted themselves
          to it, or which we believe should be accountable in this way.
        </li>
      </ul>
    </div>
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
          Wikipedia summary of <a href="http://http://en.wikipedia.org/wiki/Freedom_of_information_laws_by_country">FOI laws by country</a>.
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
      The website <a href="github.com/mysociety">github.com</a> is a central, public
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
          See the <a href="{{ site.baseurl }}installing">installation instructions</a> which will
          clone the Alaveteli repo.
        </li>
        <li>
          Everything about git from the <a
          href="//http://git-scm.com">official website</a>.
        </li>
        <li>
          See <a href="http://github.com/mysociety">the mySociety projects on
          github</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="holding pen">holding pen</a>
  </dt>
  <dd>
    The <strong>holding pen</strong> is the conceptual place where responses that 
    could not be delivered are held. They need attention from a administrator.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
			    see the <a href="{{ site.baseurl }}running/admin_manual">admin manual</a> for
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
    the <a href="#response" class="glossary">responses</a> and replies it receives.
    All this email goes through the MTA, which is a seperate service on your system.
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
			    see these instructions for <a href="{{ site.baseurl }}installing/exim4">configuring exim4</a>,
          a common MTA
        </li>
      </ul>
    </div>
    
  </dd>

  <dt>
    <a name="publish">publish</a>
  </dt>
  <dd>
    Alaveteli works by <strong>publishing</strong> the 
    <a href="#response" class="glossary">responses</a> it recieves to the 
    <a href="#foi" class="glossary">Freedom of Information</a>
    <a href="#request" class="glossary">requests</a> that its users send.
    It does this by processing the emails it receives and presenting them
    as pages &mdash; one per request &mdash; on the website. This makes it
    easy for people to find, read, link to, and share the request and the
    information provided in response.
  </dd>

  <dt>
    <a name="response">response</a>
  </dt>
  <dd>
	  A <strong>response</strong> is the email sent by an 
     <a href="#authority" class="glossary">authority</a> in reply to 
     a user's  <a href="#request" class="glossary">requests</a>.
  </dd>

  <dt>
    <a name="request">request</a>
  </dt>
  <dd>
    In Alaveteli, a <strong>request</strong> is the 
    <a href="#foi">Freedom of Information</a> request
    that a user enters, and which the site then emails to the relevant 
    <a href="#authority" class="glossary">authority</a>.
    Alaveteli automatically <a href="#publish" class="glossary">publishes</a>
    the <a href="#response" class="glossary">responses</a>
    to all the requests it sends.
  </dd>

  <dt>
    <a name="state">state</a>
  </dt>
  <dd>
    Each <a href="#request">request</a> passes through different
    <strong>states</strong> as it progresses through the system.
    States help Alaveteli administrators, as well as the public, 
    understand the current situation with any request and what 
    action, if any, is required.
    <p>
      The states available can be customised within
      your site's <a href="#theme">theme</a>.
    </p>
    <div class="more-info">
      <p>More information:</p>
      <ul>
        <li>
			    <a href="{{ site.baseurl }}/running/states">example states for WhatDoTheyKnow</a>
          (Alaveteli site running in the UK)
        </li>
        <li>
			    for comparison, <a href="{{ site.baseurl }}/running/states_informatazyrtare">example states for InformataZyrtare</a>
          (Alaveteli site running in Kosovo)
        </li>
        <li>
          to customise or add your own states, see <a href="{{ site.baseurl }}customising/themes">Customising the request states</a>
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
			<a href="/customising/themes">about themes</a>
        </li>
      </ul>
    </div>
  </dd>

</dl>