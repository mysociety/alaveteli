---
layout: page
title: High-level overview
---

# High-level overview

<p class="lead">
    This page describes the process and entities that make up Alaveteli.
    It's a high-level overview of how Alaveteli works to help you orientate yourself to the code.
</p>

_See also the [schema diagram](#schema-diagram) at the bottom of this page._

The main entity is **InfoRequest**, which represents a request for information by a
**User** to a **PublicBody**. A new InfoRequest results in an initial **OutgoingMessage**,
which represents the initial email.

Once an InfoRequest is made, its state is tracked using **InfoRequestEvents**. For
example, a new InfoRequest has an initial state of `awaiting_response` and an
associated InfoRequestEvent of type `initial_request`. An InfoRequest event can
have an OutgoingMessage or an IncomingMessage or neither associated with it.

Replies are received by the system by piping raw emails (represented by a **RawEmail**)
from the MTA to a script at `script/mailin`. This parses the email, tries to identify the
associated InfoRequest, and then generates an **IncomingMessage** which references
both the RawEmail and the InfoRequest.

Any User can make **Comments** on InfoRequests.

All events (e.g., Comments, OutgoingMessages) are tracked in InfoRequestEvent.

A **TrackThing** is a canned search that allows users to be alerted when events
matching their criteria are found. (How this worked changed after we'd
launched, so there's still some deprecated code there for things we've phased
out.)

The **MailServerLog** is a representation of the parsed MTA log files.
MailServerLog entries are created by a cron job that runs
`script/load-mail-server-logs`. This checks incoming emails and matches them
to InfoRequests; then `script/check-recent-requests-send` checkes these logs to
ensure they have an envelope-from header set (to combat spam).

## Schema diagram

<a href="{{ site.baseurl }}assets/img/railsmodels.png"><img src="{{ site.baseurl }}assets/img/railsmodels.png"></a>

This schema for the Rails models was generated from the code on 19 Dec 2012 using
[Railroad](http://railroad.rubyforge.org/).

The railroad command is: `railroad -M | dot -Tpng > railsmodels.png`
