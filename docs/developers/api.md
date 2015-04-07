---
layout: page
title: API
---

# Alaveteli API

<p class="lead">
    There are two parts to the API for accessing or inserting data programmatically: the read API, and the write API.
</p>

## Read API

This is provided via JSON versions of most entities in the system, plus atom
feeds for listing entities:

### Atom feeds

There are Atom feeds on most pages which list FOI requests, which you can use
to get updates and links in XML format. Find the URL of the Atom feed in one of
these ways:

* Look for the RSS feed links.
* Examine the `<link rel="alternate" type="application/atom+xml">` tag in the head of the HTML.
* Add `/feed` to the start of another URL.

Note that even complicated search queries have Atom feeds. You can do all sorts
of things with them, such as query by authority, by file type, by date range,
or by status. See the advanced search tips for details.

### JSON structured data

Quite a few pages have JSON versions, which let you download information about
objects in a structured form. Find them by:

* adding `.json` to the end of the URL.
* looking for the `<link rel="alternate" type="application/json">` tag in the head of the HTML.

Requests, users and authorities all have JSON versions containing basic
information about them. Every Atom feed has a JSON equivalent, containing
information about the list of events in the feed.

### Starting new requests programmatically

To encourage users to make links to a particular public authority, use URLs of
the form `http://<yoursite>/new/<publicbody_url_name>`. These are the
parameters you can add to those URLs, either in the URL or from a form:

* `title` - the default summary of the new request.
* `default_letter` - the default text of the body of the letter. The salutation and signoff for your locale are wrapped round this.
* `body` - as an alternative to `default_letter`, this sets the default entire text of the request, so you can customise the salutation and signoff.
* `tags` - space separated list of tags, so you can find and link up any requests made later, e.g. `openlylocal spending_id:12345`. The `:` indicates it is a machine tag. The values of machine tags may also include colons, useful for URIs.

## Write API

The write API is designed to be used by public bodies to create their own
requests in the system. Currently used by mySociety's [FOI
Register](https://github.com/mysociety/foi-register) software to support using
Alaveteli as a disclosure log for all FOI activity at a particular public body.

All requests must include an API key as a variable `k`. This key can be viewed
on each authority's page in the admin interface. Other variables should be sent
as follows:

* `/api/v2/request` - POST the following json data as a form variable `json` to create a new request:
  * `title` - title for the request
  * `body` - body of the request
  * `external_user_name` - name of the person who originated the request
  * `external_url` - URL where a canonical copy of the request can be found
  Returns JSON containing a `url` for the new request, and its `id`
* `/api/v2/request/<id>.json` - GET full information about a request
* `/api/v2/request/<id>.json` - POST additional correspondence regarding a request:
  * as form variable `json`:
    * `direction` - either `request` (from the user - might be a followup, reminder, etc) or `response` (from the authority)
    * `body` - the message itself
    * `state` - optional, allows the authority to include an updated request `state` value when sending an update. Allowable values: `waiting_response`, `rejected`, `successful` and `partially_successful`. Only used in the `response` direction
    * `sent_at` - ISO-8601 formatted time that the correspondence was sent
  * (optionally) the variable `attachments` as `multipart/form-data`:
    * attachments to the correspondence.  Attachments can only be attached to messages in the `response` direction
* `/api/v2/request/<id>/update.json` - POST a new state for the request:
  * as form variable `json`:
    * `state` - the user's assessment of the `state` of a request that has received a response from the authority. Allowable values: `waiting_response`, `rejected`, `successful` and `partially_successful`. Should only be used for the user's feedback, an authority wishing to update the request `state` should use `/api/v2/request/<id>.json` instead




